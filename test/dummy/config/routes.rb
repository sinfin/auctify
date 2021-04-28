# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  resources :things
  resources :users
  mount Auctify::Engine => "/", as: "auctify"

  root to: "users#index"
end
