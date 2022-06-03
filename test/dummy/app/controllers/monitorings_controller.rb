# frozen_string_literal: true

class MonitoringsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @connection_config = { url: ENV["MONITORED_APP_URL"], token: ENV["MONITORED_APP_TOKEN"] }
    download_new_record
    @records = MonitoringRecord.ordered.limit(50)
  end

  private
    def download_new_record
      MonitoringRecord.download_current(@connection_config)
    end
end
