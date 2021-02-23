# frozen_string_literal: true

Auctify::Engine.routes.draw do
  resources :bidder_registrations
  resources :sales
end
