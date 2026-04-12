# frozen_string_literal: true

module MaliPoPay
  # Base error class for all MaliPoPay errors
  class Error < StandardError
    attr_reader :http_status, :response_body

    def initialize(message = nil, http_status: nil, response_body: nil)
      @http_status = http_status
      @response_body = response_body
      super(message)
    end
  end

  # Raised when the API key is missing or invalid (401)
  class AuthenticationError < Error; end

  # Raised when the API key lacks permissions for the request (403)
  class PermissionError < Error; end

  # Raised when the requested resource is not found (404)
  class NotFoundError < Error; end

  # Raised when request parameters fail validation (400/422)
  class ValidationError < Error
    attr_reader :errors

    def initialize(message = nil, errors: nil, **kwargs)
      @errors = errors
      super(message, **kwargs)
    end
  end

  # Raised when the API rate limit is exceeded (429)
  class RateLimitError < Error
    attr_reader :retry_after

    def initialize(message = nil, retry_after: nil, **kwargs)
      @retry_after = retry_after
      super(message, **kwargs)
    end
  end

  # Raised for general API errors (5xx, unexpected responses)
  class ApiError < Error; end

  # Raised when a network connection error occurs
  class ConnectionError < Error; end
end
