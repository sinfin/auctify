# frozen_string_literal: true

Auctify::Engine.routes.draw do
  resources :bids
  resources :bidder_registrations
  resources :sales
end
