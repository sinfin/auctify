# frozen_string_literal: true

Rails.application.routes.draw do
  resources :things
  resources :users
  mount Auctify::Engine => "/", as: "auctify"

  root to: "users#index"
end
