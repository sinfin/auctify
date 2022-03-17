# frozen_string_literal: true

module Auctify
  module Sale
    class Auction < Auctify::Sale::Base
      include AASM
      include Auctify::Sale::AuctionCallbacks

      ATTRIBUTES_UNMUTABLE_AT_SOME_STATE = %i[ends_at offered_price]
      DEPENDENT_ATTRIBUTES = {
        ends_at: %i[currently_ends_at],
        offered_price: %i[current_price]
      }

      attr_accessor :winning_bid
      attr_accessor :manually_closed_price_check

      has_many :bidder_registrations, dependent: :destroy
      has_many :bids, through: :bidder_registrations, dependent: :restrict_with_error # destroy them manually first
      has_many :ordered_applied_bids,  -> { applied.ordered },
                                       through: :bidder_registrations,
                                       source: :bids,
                                       dependent: :restrict_with_error # destroy them manually first

      belongs_to :winner, polymorphic: true, optional: true
      belongs_to :current_winner, polymorphic: true, optional: true
      belongs_to :manually_closed_by, polymorphic: true, optional: true
      belongs_to :bidding_locked_by, polymorphic: true, optional: true

      validates :ends_at,
                presence: true

      scope :where_current_winner_is, ->(bidder) { where(current_winner: bidder) }
      scope :closable_automatically, -> do
        where(must_be_closed_manually: false)
      end

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
            self.current_winner = nil
            self.buyer = nil
          end

          transitions from: :accepted, to: :in_sale

          after do
            after_start_sale
          end
        end

        event :close_bidding do
          transitions from: :in_sale, to: :bidding_ended

          after do
            self.winner = current_winner
            now = Time.current
            self.currently_ends_at = now if now < currently_ends_at

            after_close_bidding
            process_bidding_result! if configuration.autofinish_auction_after_bidding == true
          end
        end

        event :sold_in_auction do
          before do |*args|
            params = args.first # expecting keys :buyer, :price
            self.buyer = params[:buyer]
            self.sold_price = params[:price]
            self.sold_at = params[:sold_at] || currently_ends_at
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
      validate :forbidden_changes
      validate :validate_manually_closed
      validate :validate_bidding_locked

      after_create :autoregister_bidders
      after_save :create_jobs
      before_destroy :forbid_destroy_if_there_are_bids, prepend: true

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

      def offered_price=(value)
        super

        self.current_price = value if current_price.present?
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

      # callback from bid_appender
      def succesfull_bid!(price:, winner:, time:)
        return false if price < current_price || time.blank?

        self.current_price = price
        self.current_winner = winner
        self.applied_bids_count = ordered_applied_bids.size
        extend_end_time(time)

        save!
      end

      def recalculate_bidding!
        self.applied_bids_count = ordered_applied_bids.size

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

      def current_max_price_for(bidder, bids_array: nil)
        bids_array ||= ordered_applied_bids.with_limit

        last_bidder_mx_bid = bids_array.detect { |bid| !bid.max_price.nil? && bid.bidder == bidder }

        last_bidder_mx_bid.blank? ? 0 : last_bidder_mx_bid.max_price
      end

      def open_for_bids?
        if must_be_closed_manually?
          !manually_closed_at && in_sale?
        else
          in_sale? && Time.current <= currently_ends_at
        end
      end

      def opening_price
        offered_price
      end

      def allows_new_bidder_registrations?
        @allows_new_bidder_registrations ||= (in_sale? || accepted?)
      end

      def bidding_allowed_for?(bidder)
        babm = bidding_allowed_by_method_for?(bidder)
        babm.nil? ? true : babm # if no method defined => allow
      end

      def locked_for_modifications?
        applied_bids_count.positive?
      end

      def auction_prolonging_limit_in_seconds
        pack&.auction_prolonging_limit_in_seconds || Auctify.configuration.auction_prolonging_limit_in_seconds
      end

      def close_manually(by:, price_check:)
        if manually_closed_at.nil? && update(manually_closed_at: Time.current, manually_closed_by: by, manually_closed_price_check: price_check)
          Auctify::BiddingCloserJob.perform_later(auction_id: id)
          true
        else
          false
        end
      end

      def lock_bidding(by:)
        !!update(bidding_locked_at: Time.current, bidding_locked_by: by)
      end

      def unlock_bidding(by:)
        !!update(bidding_locked_at: nil, bidding_locked_by: nil)
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
          new_end_time = bid_time + auction_prolonging_limit_in_seconds
          self.currently_ends_at = [currently_ends_at, new_end_time].max
        end

        def process_bidding_result!
          case success?
          when true
            sold_in_auction!(buyer: current_winner, price: current_price, sold_at: currently_ends_at)
          when false
            not_sold_in_auction!
          else
            # => nil
          end
        end

        def bidding_is_close_to_end_notification_time
          configured_period = Auctify.configuration.when_to_notify_bidders_before_end_of_bidding
          return nil if configured_period.blank?

          ends_at - configured_period
        end

        def forbidden_changes
          ATTRIBUTES_UNMUTABLE_AT_SOME_STATE.each do |att|
            next if configuration.allow_changes_on_auction_with_bids_for_attributes.include?(att.to_sym)

            if changes[att].present? && locked_for_modifications?
              errors.add(att, :no_modification_allowed_now)
              write_attribute(att, changes[att].first)
              DEPENDENT_ATTRIBUTES[att].each do |datt|
                write_attribute(datt, changes[datt].first) if changes[datt].present?
              end
            end
          end
        end

        def forbid_destroy_if_there_are_bids
          errors.add(:base, :you_cannot_delete_auction_with_bids) if bids.any?
        end

        def create_jobs(force = false)
          return unless in_sale?

          currently_ends_at_changes = saved_changes["currently_ends_at"]

          if force || currently_ends_at_changes.present?
            if (notify_time = bidding_is_close_to_end_notification_time).present?
              # remove_old job is unsupported in ActiveJob
              Auctify::BiddingIsCloseToEndNotifierJob.set(wait_until: notify_time)
                                                     .perform_later(auction_id: id)
            end
          end
        end

        def validate_manually_closed
          return unless will_save_change_to_manually_closed_at?

          if manually_closed_at
            unless bidding_locked_at?
              errors.add(:base, :need_to_lock_bidding_first)
            end

            if !manually_closed_price_check || manually_closed_price_check.to_i != current_price
              errors.add(:base, :current_price_doesnt_match_closing)
            end

            unless must_be_closed_manually?
              errors.add(:base, :sales_not_closed_manually)
            end

            unless manually_closed_by.is_a?(Folio::Account)
              errors.add(:manually_closed_by, :not_allowed)
            end
          end
        end

        def validate_bidding_locked
          return unless will_save_change_to_bidding_locked_at?

          if bidding_locked_at?
            unless bidding_locked_by.is_a?(Folio::Account)
              errors.add(:bidding_locked_by, :not_allowed)
            end
          end
        end
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id                           :bigint(8)        not null, primary key
#  seller_type                  :string
#  seller_id                    :integer
#  buyer_type                   :string
#  buyer_id                     :bigint(8)
#  item_id                      :bigint(8)        not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  type                         :string           default("Auctify::Sale::Base")
#  aasm_state                   :string           default("offered"), not null
#  offered_price                :decimal(12, 2)
#  current_price                :decimal(12, 2)
#  sold_price                   :decimal(12, 2)
#  bid_steps_ladder             :jsonb
#  reserve_price                :decimal(, )
#  pack_id                      :bigint(8)
#  ends_at                      :datetime
#  position                     :integer
#  number                       :string
#  currently_ends_at            :datetime
#  published                    :boolean          default(FALSE)
#  slug                         :string
#  contract_number              :string
#  seller_commission_in_percent :integer
#  winner_type                  :string
#  winner_id                    :bigint(8)
#  applied_bids_count           :integer          default(0)
#  sold_at                      :datetime
#  current_winner_type          :string
#  current_winner_id            :bigint(8)
#  buyer_commission_in_percent  :integer
#  featured                     :integer
#  manually_closed_at           :datetime
#  manually_closed_by_type      :string
#  manually_closed_by_id        :bigint(8)
#  must_be_closed_manually      :boolean          default(FALSE)
#  bidding_locked_at            :datetime
#  bidding_locked_by_type       :string
#  bidding_locked_by_id         :bigint(8)
#
# Indexes
#
#  index_auctify_sales_on_aasm_state                 (aasm_state)
#  index_auctify_sales_on_bidding_locked_by          (bidding_locked_by_type,bidding_locked_by_id)
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_currently_ends_at          (currently_ends_at)
#  index_auctify_sales_on_featured                   (featured)
#  index_auctify_sales_on_manually_closed_by         (manually_closed_by_type,manually_closed_by_id)
#  index_auctify_sales_on_must_be_closed_manually    (must_be_closed_manually)
#  index_auctify_sales_on_pack_id                    (pack_id)
#  index_auctify_sales_on_position                   (position)
#  index_auctify_sales_on_published                  (published)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#  index_auctify_sales_on_slug                       (slug) UNIQUE
#  index_auctify_sales_on_winner_type_and_winner_id  (winner_type,winner_id)
#

#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_currently_ends_at          (currently_ends_at)
#  index_auctify_sales_on_featured                   (featured)
#  index_auctify_sales_on_pack_id                    (pack_id)
#  index_auctify_sales_on_position                   (position)
#  index_auctify_sales_on_published                  (published)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#  index_auctify_sales_on_slug                       (slug) UNIQUE
#  index_auctify_sales_on_winner_type_and_winner_id  (winner_type,winner_id)
#
