# frozen_string_literal: true

Auctify::Engine.routes.draw do
  namespace :auctify do
    resources :bids
    resources :bidder_registrations
    resources :sales

    namespace :api do
      namespace :v1 do
        resources :auctions do
          member do
            post :bids
          end
        end

        namespace :console do
          resources :bids, only: %i[destroy]
        end
      end
    end
  end
end
