# frozen_string_literal: true

Auctify::Engine.routes.draw do
  namespace :auctify do
    resources :sales_packs
    resources :bids
    resources :bidder_registrations
    resources :sales
  end
end
