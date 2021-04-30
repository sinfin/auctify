# frozen_string_literal: true

Rails.application.routes.draw do
  resources :things
  resources :users
  mount Auctify::Engine => "/", as: "auctify"

  namespace :auctify do
    resources :sales_packs
    resources :sales
  end

  root to: "users#index"
end
