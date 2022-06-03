# frozen_string_literal: true

require "test_helper"

class MonitoringRecordDownloaderTest < ActiveSupport::TestCase
  attr_reader :config_hash, :downloaded_data_json

  HttpResponseStubStruct = Struct.new(:code, :body, :uri)

  def setup
    super
    @config_hash = { url: "https://some.auctified.app/", token: "AccessToken5" }
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

  test "downloads and store new remote data" do
    api_response = HttpResponseStubStruct.new("200",
                                              downloaded_data_json,
                                              URI.parse(config_hash[:url]))

    fake_http = Minitest::Mock.new
    fake_http.expect(:request, api_response, [Net::HTTPRequest])

    service = Net::HTTP.stub(:start, fake_http) do
      assert_difference("MonitoringRecord.count", +1) do
        MonitoringRecordDownloader.call(config_hash)
      end
    end

    expected_response_body = JSON.parse(downloaded_data_json).deep_symbolize_keys

    assert service.success?, "Service should be success"
    assert_equal 200, service.result.code
    assert_equal expected_response_body, service.result.response
    assert service.errors.blank?, "Errors should be empty"

    assert_equal downloaded_data_json, MonitoringRecord.last.data
  end

  test "can handle connection errors" do
    MonitoringRecordDownloader::KNOWN_CONNECTION_ERRORS.each do |error_class|
      expected_err_message = "#{error_class} > #{config_hash[:url]} - #{error_class.new.message}"
      raises_exception = -> (*args) { raise error_class }

      service = Net::HTTP.stub(:start, raises_exception) do
        MonitoringRecordDownloader.call(config_hash)
      end

      assert service.failure?, "Service should fail for #{error_class}"
      assert_equal 500, service.result.code, "result.code should be 500 for #{error_class}"
      assert_equal "", service.result.response, "result.response should be '' for #{error_class}"
      assert_includes service.errors[:connection], expected_err_message
    end
  end

  test "can handle api errors" do
    response_body = '{
                        "message": "Wrong token"
                      }'
    api_error_response = HttpResponseStubStruct.new("401",
                                                    response_body,
                                                    URI.parse(config_hash[:url]))

    fake_http = Minitest::Mock.new
    fake_http.expect(:request, api_error_response, [Net::HTTPRequest])

    service = Net::HTTP.stub(:start, fake_http) do
      MonitoringRecordDownloader.call(config_hash)
    end

    expected_response_body = JSON.parse(response_body).deep_symbolize_keys
    assert service.failure?, "Service should fail for 401"
    assert_equal 401, service.result.code
    assert_equal expected_response_body, service.result.response
    assert_includes service.errors[:api], response_body
  end
end
