# frozen_string_literal: true

module Auctify
  module Sale
    class Auction < Auctify::Sale::Base
      include AASM
      include Auctify::Sale::AuctionCallbacks

      attr_accessor :winning_bid

      has_many :bidder_registrations, dependent: :destroy
      has_many :bids, through: :bidder_registrations, dependent: :destroy
      has_many :applied_bids, class_name: "Auctify::Bid", through: :bidder_registrations

      belongs_to :winner, polymorphic: true, optional: true

      validates :ends_at,
                presence: true

      aasm do
        state :offered, initial: true, color: "red"
        state :accepted, color: "red"
        state :refused, color: "dark"
        state :in_sale, color: "yellow"
        state :bidding_ended, color: "yellow"
        state :auctioned_successfully, color: "green"
        state :auctioned_unsuccessfully, color: "red"
        state :sold, color: "green"
        state :not_sold, color: "dark"
        state :cancelled, color: "red"

        event :accept_offer do
          transitions from: :offered, to: :accepted
        end

        event :refuse_offer do
          transitions from: :offered, to: :refused
        end

        event :start_sale do
          before do
            self.current_price = self.offered_price
            self.currently_ends_at = self.ends_at
            self.buyer = nil
          end

          transitions from: :accepted, to: :in_sale

          after do
            set_bidding_closer_job
            set_bidding_is_close_to_end_job
            after_start_sale
          end
        end

        event :close_bidding do
          transitions from: :in_sale, to: :bidding_ended

          after do
            self.winner = current_winner
            after_close_bidding
            process_bidding_result! if configuration.autofinish_auction_after_bidding == true
          end
        end

        event :sold_in_auction do
          before do |*args| # TODO: sold_at
            params = args.first # expecting keys :buyer, :price
            self.buyer = params[:buyer]
            self.sold_price = params[:price]
          end

          transitions from: :bidding_ended, to: :auctioned_successfully, if: :valid?

          after do
            after_sold_in_auction
          end
        end

        event :not_sold_in_auction do
          transitions from: :bidding_ended, to: :auctioned_unsuccessfully, if: :no_winner?

          after do
            after_not_sold_in_auction
          end
        end

        event :sell do
          transitions from: :auctioned_successfully, to: :sold
        end

        event :end_sale do
          transitions from: :auctioned_unsuccessfully, to: :not_sold
        end

        event :cancel do
          transitions from: [:offered, :accepted], to: :cancelled
        end
      end

      validate :buyer_vs_bidding_consistence

      after_create :autoregister_bidders

      def bidders
        @bidders ||= bidder_registrations.collect { |br| br.bidder }.sort_by(&:name)
      end

      def published=(value)
        super

        if published?
          accept_offer if offered?
          start_sale if accepted?
        end
      end

      def ends_at=(value)
        super

        self.currently_ends_at = value if currently_ends_at.present?
      end

      def success?
        return nil if offered? || accepted? || refused? || cancelled? || in_sale? # or raise error?
        return true if auctioned_successfully? || sold?
        return false if auctioned_unsuccessfully? || not_sold?

        applied_bids_count.positive? && ((reserve_price || 0) <= current_price)
      end

      def bid!(bid)
        ensure_registration(bid)

        ActiveRecord::Base.transaction do
          bid.created_at ||= Time.current

          bap = Auctify::BidsAppender.call(auction: self, bid: bid)

          bap.success? ? after_bid_appended(bap) : after_bid_not_appended(bap)
          bap.success?
        end
      end

      def recalculate_bidding!
        self.applied_bids_count = applied_bids.size

        if applied_bids_count.zero?
          self.current_price = offered_price
        else
          winning_price = bidding_result.winning_bid.price
          self.current_price = winning_price if current_price > winning_price
        end

        save!
      end

      delegate :winning_bid, to: :bidding_result
      def bidding_result
        Auctify::BidsAppender.call(auction: self, bid: nil).result
      end

      def current_winner
        bidding_result.winner
      end

      def current_winning_bid
        bidding_result.winning_bid
      end

      def previous_winning_bid(relative_to_bid = nil)
        return nil if bids.empty?

        relative_to_bid ||= current_winning_bid
        considered_bids = bids.ordered.drop_while { |b| b != relative_to_bid }
        considered_bids.second
      end


      def current_minimal_bid
        bidding_result.current_minimal_bid
      end

      def open_for_bids?
        in_sale? && Time.current <= currently_ends_at
      end

      def opening_price
        offered_price
      end

      def allows_new_bidder_registrations?
        @allows_new_bidder_registrations ||= (in_sale? || accepted?)
      end

      def succesfull_bid!(price:, time:)
        return false if price < current_price || time.blank?

        self.current_price = price
        self.applied_bids_count = applied_bids.size
        extend_end_time(time)
        save!
      end

      def bidding_allowed_for?(bidder)
        babm = bidding_allowed_by_method_for?(bidder)
        babm.nil? ? true : babm # if no method defined => allow
      end

      private
        def buyer_vs_bidding_consistence
          return true if buyer.blank? && sold_price.blank?

          unless buyer == winner
            errors.add(:buyer,
                       :buyer_is_not_the_winner,
                       buyer: buyer.to_label,
                       winner: winner.to_label)
          end

          unless sold_price == bidding_result.won_price
            errors.add(:sold_price,
                       :sold_price_is_not_from_bidding,
                       sold_price: sold_price,
                       won_price: bidding_result.won_price)
          end
        end

        def no_winner?
          return true if winner.blank?
          errors.add(:buyer,
            :there_is_a_buyer_for_not_sold_auction,
             winner: winner.to_label)
          false
        end

        def autoregister_bidders
          class_names = configuration.autoregister_as_bidders_all_instances_of_classes.to_a
          return if class_names.blank?

          @allows_new_bidder_registrations = true

          class_names.each do |class_name|
            class_name.constantize.find_each { |bidder| create_registration(bidder) }
          end

          @allows_new_bidder_registrations = false
        end

        def ensure_registration(bid)
          bid.registration = create_registration(bid.bidder) if autocreate_registration?(bid)
        end

        def autocreate_registration?(bid)
          return false  if bid.registration.present?
          return true if configuration.autoregistering_for?(bid.bidder)

          babm = bidding_allowed_by_method_for?(bid.bidder)
          babm.nil? ? false : babm # if no method defined, do not create
        end

        def create_registration(bidder)
          self.bidder_registrations.approved.create!(bidder: bidder, handled_at: Time.current)
        end

        def bidding_allowed_by_method_for?(bidder)
          return false if bidder.blank?
          bidder.try(:bidding_allowed?)
        end

        def extend_end_time(bid_time)
          new_end_time = bid_time + Auctify.configuration.auction_prolonging_limit
          self.currently_ends_at = [currently_ends_at, new_end_time].max
        end

        def set_bidding_closer_job
          Auctify::BiddingCloserJob.set(wait_until: currently_ends_at)
                                   .perform_later(auction_id: id)
        end

        def process_bidding_result!
          case success?
          when true
            sold_in_auction!(buyer: current_winner, price: current_price)
          when false
            not_sold_in_auction!
          else
            # => nil
          end
        end

        def set_bidding_is_close_to_end_job
          configured_period = Auctify.configuration.when_to_notify_bidders_before_end_of_bidding
          notify_time = ends_at - configured_period
          Auctify::BiddingIsCloseToEndNotifierJob.set(wait_until: notify_time)
                                                 .perform_later(auction_id: id)
        end
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id                    :bigint(8)        not null, primary key
#  seller_type           :string
#  seller_id             :integer
#  buyer_type            :string
#  buyer_id              :bigint(8)
#  item_id               :bigint(8)        not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  type                  :string           default("Auctify::Sale::Base")
#  aasm_state            :string           default("offered"), not null
#  offered_price         :decimal(12, 2)
#  current_price         :decimal(12, 2)
#  sold_price            :decimal(12, 2)
#  bid_steps_ladder      :jsonb
#  reserve_price         :decimal(, )
#  pack_id               :bigint(8)
#  ends_at               :datetime
#  position              :integer
#  number                :string
#  currently_ends_at     :datetime
#  published             :boolean          default(FALSE)
#  featured              :boolean          default(FALSE)
#  slug                  :string
#  contract_number       :string
#  commission_in_percent :integer
#  winner_type           :string
#  winner_id             :bigint(8)
#  applied_bids_count    :integer          default(0)
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_featured                   (featured)
#  index_auctify_sales_on_pack_id                    (pack_id)
#  index_auctify_sales_on_position                   (position)
#  index_auctify_sales_on_published                  (published)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#  index_auctify_sales_on_slug                       (slug) UNIQUE
#  index_auctify_sales_on_winner_type_and_winner_id  (winner_type,winner_id)
#
