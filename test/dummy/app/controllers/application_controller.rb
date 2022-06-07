# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  before_action do
    Yabeda.auctify.db_whistles_blows_total.increment(kind: "success", db_server: "name_of_db_server_from_config")
  end
end
