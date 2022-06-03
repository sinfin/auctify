# frozen_string_literal: true

class MonitoringRecordDownloader < Auctify::ServiceBase
  KNOWN_CONNECTION_ERRORS = [
        Timeout::Error,
        Errno::EINVAL,
        Errno::ECONNRESET,
        EOFError,
        SocketError,
        Net::ReadTimeout,
        Net::HTTPBadResponse,
        Net::HTTPHeaderSyntaxError,
        Net::ProtocolError
      ].freeze

  attr_reader :configuration
  attr_accessor :response

  ApiCallerResult = Struct.new(:code, :response, keyword_init: true)

  def initialize(configuration)
    super()

    @configuration = configuration
  end

  def build_result
    self.response = https_conn.request(request)
    process_response
  rescue *KNOWN_CONNECTION_ERRORS => e
    handle_connection_error(e)
  end

  private
    def https_conn
      @https_conn ||= Net::HTTP.start(service_uri.host, service_uri.port, connection_options)
    end

    def request
      request = Net::HTTP::Get.new service_uri.request_uri, headers # request_uri => path + query

      debug_msg = "Auctified REQUEST: #{request} to #{service_uri}" \
                  " with headers: #{headers}\n and body:\n#{request.body}"
      Rails.logger.debug(debug_msg)

      request
    end

    def process_response
      Rails.logger.debug("Auctified RESPONSE: #{response} with body:\n#{response.body}")

      if api_error?
        @failed = true
        errors.add(:api, response.body)
      else
        MonitoringRecord.create!(data: response.body)
      end

      @result = ApiCallerResult.new(code: response.code.to_i, response: parsed_response_body)
    end

    def handle_connection_error(error)
      errors.add(:connection, "#{error.class} > #{service_uri} - #{error}" )
      @failed = true
      @result = ApiCallerResult.new(code: 500, response: "")
    end

    def service_uri
      @service_uri ||= URI.parse(configuration[:url])
    end

    def headers
      { 'Content-Type': "application/json",
        'token': configuration[:token] }
    end

    def connection_options
      {
        use_ssl: true,
        verify_mode: OpenSSL::SSL::VERIFY_PEER,
        keep_alive_timeout: 30,
        # ciphers: secure_and_available_ciphers,
        # cert: OpenSSL::X509::Certificate.new(File.read(configuration.certificate_path)),
        # cert_password: configuration.certificate_password,
        # key: OpenSSL::PKey::RSA.new(File.read(configuration.private_key_path), configuration.private_key_password),
        # cert_store: post_signum_ca_store
      }
    end

    def parsed_response_body
      parsed = JSON.parse(response.body)
      if parsed.is_a?(Array)
        parsed.collect(&:deep_symbolize_keys)
      else
        parsed.deep_symbolize_keys
      end
    end

    def api_error?
      [200].exclude?(response.code.to_i)
    end

    # def secure_and_available_ciphers
    #   # Available non-weak suites for b2b.postaonline.cz (https://www.ssllabs.com/ssltest/analyze.html?d=b2b.postaonline.cz)
    #   # TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (0xc030)   ECDH secp384r1 (eq. 7680 bits RSA)   FS	256
    #   # TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (0xc02f)   ECDH secp384r1 (eq. 7680 bits RSA)   FS
    #   # which have following names in OpenSSL (see `openssl ciphers`)

    #   %w[ECDHE-RSA-AES256-GCM-SHA384 ECDHE-RSA-AES128-GCM-SHA256]
    # end
end
