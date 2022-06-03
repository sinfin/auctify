# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  resources :things
  resources :users
  resources :monitorings, only: :index

  mount Auctify::Engine => "/", as: "auctify"

  namespace :auctify do
    resources :sales_packs
    resources :sales
  end

  root to: "users#index"
end
