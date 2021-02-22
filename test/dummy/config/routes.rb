# frozen_string_literal: true

Rails.application.routes.draw do
  resources :things
  resources :users
  mount Auctify::Engine => "/auctify"

  root to: "users#index"
end
