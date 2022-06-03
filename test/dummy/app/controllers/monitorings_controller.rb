# frozen_string_literal: true

class MonitoringsController < ApplicationController
  skip_before_action :authenticate_user!
  REFRESH_TIME_SECS = 10

  # TODO make index to self refresh

  def index
    @connection_config = { url: ENV["MONITORED_APP_URL"], token: ENV["MONITORED_APP_TOKEN"] }
    srv = MonitoringRecordDownloader.call(@connection_config)

    flash[:error] = srv.errors.join("; ") if srv.failed?

    @records = MonitoringRecord.ordered.limit(50)
  end
end
