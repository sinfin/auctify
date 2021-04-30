# frozen_string_literal: true

Auctify::Engine.routes.draw do
  namespace :auctify do
    resources :bids
    resources :bidder_registrations
  end
end
