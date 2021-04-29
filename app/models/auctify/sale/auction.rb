# frozen_string_literal: true

module Auctify
  module Sale
    class Auction < Auctify::Sale::Base
      include AASM

      attr_accessor :winning_bid

      has_many :bidder_registrations, dependent: :destroy
      has_many :bids, through: :bidder_registrations, dependent: :destroy

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
            run_bidding_closer_job!
          end
        end

        event :close_bidding do
          transitions from: :in_sale, to: :bidding_ended
          after do
            run_close_bidding_callback!
          end
        end

        event :sold_in_auction do
          transitions from: :bidding_ended, to: :auctioned_successfully, if: :valid?

          before do |*args| # TODO: sold_at
            params = args.first # expecting keys :buyer, :price
            self.buyer = params[:buyer]
            self.sold_price = params[:price]
          end
        end

        event :not_sold_in_auction do
          transitions from: :bidding_ended, to: :auctioned_unsuccessfully, if: :no_winner?
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

      def bid!(bid)
        ActiveRecord::Base.transaction do
          bid.created_at ||= Time.current

          bap = Auctify::BidsAppender.call(auction: self, bid: bid)
          return true if bap.success?
          # errors can be in `bid.errors` or as `bap.errors`
          return false
        end
      end

      delegate :winning_bid, to: :bidding_result

      def bidding_result
        Auctify::BidsAppender.call(auction: self, bid: nil).result
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
        extend_end_time(time)
        self.save!
      end

      private
        def buyer_vs_bidding_consistence
          return true if buyer.blank? && sold_price.blank?

          unless buyer == bidding_result.winner
            errors.add(:buyer,
                       :buyer_is_not_the_winner,
                       buyer: buyer.to_label,
                       winner: bidding_result.winner.to_label)
          end

          unless sold_price == bidding_result.won_price
            errors.add(:sold_price,
                       :sold_price_is_not_from_bidding,
                       sold_price: sold_price,
                       won_price: bidding_result.won_price)
          end
        end

        def no_winner?
          return true if bidding_result.winner.blank?
          errors.add(:buyer,
            :there_is_a_buyer_for_not_sold_auction,
             winner: bidding_result.winner.to_label)
          false
        end

        def autoregister_bidders
          classes = configuration.autoregister_as_bidders_all_instances_of_classes.to_a
          return if classes.blank?

          @allows_new_bidder_registrations = true

          classes.each do |klass|
            klass.all.each { |bidder| self.bidder_registrations.approved.create!(bidder: bidder, handled_at: Time.current) }
            # requires activerecord-import gem
            # bidder_registrations = klass.all.collect { |bidder| Auctify::BidderRegistration.new(bidder: bidder, auction: self, state: :approved) }
            # Auctify::BidderRegistration.import bidder_registrations
          end

          @allows_new_bidder_registrations = false
        end

        def extend_end_time(bid_time)
          new_end_time = bid_time + Auctify.configuration.auction_prolonging_limit
          self.currently_ends_at = [currently_ends_at, new_end_time].max
        end

        def run_close_bidding_callback!
          job = configuration.job_to_run_after_bidding_ends
          job.perform_later(auction_id: id) if job
        end

        def run_bidding_closer_job!
          Auctify::BiddingCloserJob.set(wait_until: currently_ends_at)
                                   .perform_later(auction_id: id)
        end
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id                :bigint(8)        not null, primary key
#  seller_type       :string
#  seller_id         :integer
#  buyer_type        :string
#  buyer_id          :bigint(8)
#  item_id           :bigint(8)        not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  type              :string           default("Auctify::Sale::Base")
#  aasm_state        :string           default("offered"), not null
#  offered_price     :decimal(12, 2)
#  current_price     :decimal(12, 2)
#  sold_price        :decimal(12, 2)
#  bid_steps_ladder  :jsonb
#  reserve_price     :decimal(, )
#  pack_id           :bigint(8)
#  ends_at           :datetime
#  position          :integer
#  number            :string
#  currently_ends_at :datetime
#  published         :boolean          default(FALSE)
#  featured          :boolean          default(FALSE)
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_featured                   (featured)
#  index_auctify_sales_on_pack_id                    (pack_id)
#  index_auctify_sales_on_position                   (position)
#  index_auctify_sales_on_published                  (published)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#
