# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module MaliPoPay
  class HttpClient
    BASE_URLS = {
      production: "https://core-prod.malipopay.co.tz",
      uat: "https://core-uat.malipopay.co.tz"
    }.freeze

    RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze

    def initialize(api_key:, environment: :production, base_url: nil, timeout: 30, retries: 2)
      @api_key = api_key
      @base_url = base_url || BASE_URLS.fetch(environment.to_sym) do
        raise ArgumentError, "Invalid environment: #{environment}. Use :production or :uat"
      end
      @timeout = timeout
      @retries = retries
    end

    def get(path, params: {})
      execute(:get, path, params: params)
    end

    def post(path, body: {})
      execute(:post, path, body: body)
    end

    def put(path, body: {})
      execute(:put, path, body: body)
    end

    def delete(path, params: {})
      execute(:delete, path, params: params)
    end

    private

    def connection
      @connection ||= Faraday.new(url: @base_url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/

        conn.request :retry,
                     max: @retries,
                     interval: 0.5,
                     interval_randomness: 0.5,
                     backoff_factor: 2,
                     retry_statuses: RETRYABLE_STATUS_CODES,
                     methods: %i[get post put delete],
                     retry_block: ->(env, _opts, _retries, _exc) {
                       env.request_headers["X-Retry-Count"] = _retries.to_s
                     }

        conn.headers["apiToken"] = @api_key
        conn.headers["Content-Type"] = "application/json"
        conn.headers["Accept"] = "application/json"
        conn.headers["User-Agent"] = "malipopay-ruby/#{MaliPoPay::VERSION}"

        conn.options.timeout = @timeout
        conn.options.open_timeout = 10

        conn.adapter Faraday.default_adapter
      end
    end

    def execute(method, path, params: {}, body: {})
      response = case method
                 when :get
                   connection.get(path) { |req| req.params = params unless params.empty? }
                 when :post
                   connection.post(path, body)
                 when :put
                   connection.put(path, body)
                 when :delete
                   connection.delete(path) { |req| req.params = params unless params.empty? }
                 end

      handle_response(response)
    rescue Faraday::ConnectionFailed => e
      raise MaliPoPay::ConnectionError.new("Connection failed: #{e.message}")
    rescue Faraday::TimeoutError => e
      raise MaliPoPay::ConnectionError.new("Request timed out: #{e.message}")
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 400
        raise MaliPoPay::ValidationError.new(
          error_message(response),
          errors: response.body&.dig("errors"),
          http_status: response.status,
          response_body: response.body
        )
      when 401
        raise MaliPoPay::AuthenticationError.new(
          error_message(response),
          http_status: response.status,
          response_body: response.body
        )
      when 403
        raise MaliPoPay::PermissionError.new(
          error_message(response),
          http_status: response.status,
          response_body: response.body
        )
      when 404
        raise MaliPoPay::NotFoundError.new(
          error_message(response),
          http_status: response.status,
          response_body: response.body
        )
      when 422
        raise MaliPoPay::ValidationError.new(
          error_message(response),
          errors: response.body&.dig("errors"),
          http_status: response.status,
          response_body: response.body
        )
      when 429
        raise MaliPoPay::RateLimitError.new(
          error_message(response),
          retry_after: response.headers["Retry-After"]&.to_i,
          http_status: response.status,
          response_body: response.body
        )
      else
        raise MaliPoPay::ApiError.new(
          error_message(response),
          http_status: response.status,
          response_body: response.body
        )
      end
    end

    def error_message(response)
      body = response.body
      if body.is_a?(Hash)
        body["message"] || body["error"] || "API error (#{response.status})"
      else
        "API error (#{response.status})"
      end
    end
  end
end
