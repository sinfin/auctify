# frozen_string_literal: true

Rails.application.routes.draw do
  mount Auctify::Engine => "/auctify"
end
