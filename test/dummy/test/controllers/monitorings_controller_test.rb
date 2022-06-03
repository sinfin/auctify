# frozen_string_literal: true

require "test_helper"

puts("loading monitoring test")
class MonitoringsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @existing_monitoring_records = monitoring_records(:ok1, :ok2, :bad3)
    @downloaded_data_json = '{"status":"ok",
      "timestamp":"2022-06-02T13:19:05.023Z",
      "results":{
        "bids_count":161,
        "avg_diff_in_closing_time_secs":35,
        "max_diff_in_closing_time_secs":433,
        "avg_time_diff_between_bids_secs":73,
        "queue_sizes":{
          "in_progress":0,
          "queued":5,
          "finished":106,
          "failed":6,
          "dead":0,
          "retries":1,
          "critical":0,
          "mailers":1,
          "default":1,
          "scheduled":0
        }
      }
    }'
  end

  test "index should grab new record from remote API and display last 50 records" do
    expected_config_hash = { url: "https://some.auctified.app/", token: "AccessToken5" }

    mr_mock = Minitest::Mock.new
    mr_mock.expect(:call, true, [expected_config_hash])

    MonitoringRecord.stub(:download_current, mr_mock) do
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
end
