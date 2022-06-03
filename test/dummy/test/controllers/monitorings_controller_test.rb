# frozen_string_literal: true

require "test_helper"

puts("loading monitoring test")
class MonitoringsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @existing_monitoring_records = monitoring_records(:ok1, :ok2, :bad3)
  end

  test "index should grab new record from remote API and display last 50 records" do
    expected_config_hash = { url: "https://some.auctified.app/auctify_status.json", token: "AccessToken5" }

    mr_mock = Minitest::Mock.new
    mr_mock.expect(:call, SuccessfulService.new, [expected_config_hash])

    MonitoringRecordDownloader.stub(:call, mr_mock) do
      ENV["MONITORED_APP_URL"] = expected_config_hash[:url]
      ENV["MONITORED_APP_TOKEN"] = expected_config_hash[:token]

      get monitorings_url

      assert_response :success

      ENV["MONITORED_APP_URL"] = ""
      ENV["MONITORED_APP_TOKEN"] = ""
    end

    mr_mock.verify

    assert_includes response.body, expected_config_hash[:url]
    @existing_monitoring_records.each do |m_record|
      assert_includes response.body, JSON.parse(m_record.data)["timestamp"]
    end
    # TODO: dowloaded record should be here too
  end

  private

  # successful by doing nothing
  class SuccessfulService < Auctify::ServiceBase
    def build_result
    end
  end
end
