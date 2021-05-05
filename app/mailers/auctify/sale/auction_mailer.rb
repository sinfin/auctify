# frozen_string_literal: true

class Auctify::Sale::AuctionMailer < ApplicationMailer
  def new_bid(bid)
    return unless bid.bidder.respond_to?(:email)

    data = new_bid_data(bid)
    email_template_mail(data, to: bid.bidder.email)
  end

  def new_bid_with_limit(bid)
    return unless bid.bidder.respond_to?(:email)

    data = new_bid_with_limit_data(bid)
    email_template_mail(data, to: bid.bidder.email)
  end

  def admin_new_bid(bid)
    data = new_bid_data(bid).merge(admin_bid_data(bid))
    email_template_mail(data)
  end

  def admin_new_bid_with_limit(bid)
    data = new_bid_with_limit_data(bid).merge(admin_bid_data(bid))
    email_template_mail(data)
  end

  private
    def new_bid_data(bid)
      {
        BID_PRICE: ActionController::Base.helpers.number_to_currency(bid.price, precision: 0),
        AUCTION_NUMBER: bid.auction.number,
        AUCTION_TITLE: bid.auction.item.try(:to_label),
        AUCTION_URL: auctify_sales_pack_auctify_sale_auction_url(bid.auction.pack, bid.auction),
      }
    end

    def new_bid_with_limit_data(bid)
      new_bid_data(bid).merge(
        BID_MAX_PRICE: ActionController::Base.helpers.number_to_currency(bid.max_price, precision: 0),
      )
    end

    def admin_bid_data(bid)
      {
        # TODO: add bidder number (registration number?)
        BIDDER_NUMBER: bid.registration.id,
        BIDDER_NAME: bid.bidder.try(:full_name),
      }
    end
end
