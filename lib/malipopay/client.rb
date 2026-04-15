# frozen_string_literal: true

module Malipopay
  class Client
    attr_reader :http_client, :webhook_secret

    # Initialize a new Malipopay client
    #
    # @param api_key [String] Your Malipopay API token
    # @param environment [Symbol] :production or :uat (default: :production)
    # @param base_url [String, nil] Override the base URL
    # @param timeout [Integer] Request timeout in seconds (default: 30)
    # @param retries [Integer] Number of retries on failure (default: 2)
    # @param webhook_secret [String, nil] Secret for verifying webhooks
    def initialize(api_key:, environment: :production, base_url: nil, timeout: 30, retries: 2, webhook_secret: nil)
      raise ArgumentError, "api_key is required" if api_key.nil? || api_key.empty?

      @http_client = HttpClient.new(
        api_key: api_key,
        environment: environment,
        base_url: base_url,
        timeout: timeout,
        retries: retries
      )
      @webhook_secret = webhook_secret
    end

    # @return [Malipopay::Resources::Payments]
    def payments
      @payments ||= Resources::Payments.new(@http_client)
    end

    # @return [Malipopay::Resources::Customers]
    def customers
      @customers ||= Resources::Customers.new(@http_client)
    end

    # @return [Malipopay::Resources::Invoices]
    def invoices
      @invoices ||= Resources::Invoices.new(@http_client)
    end

    # @return [Malipopay::Resources::Products]
    def products
      @products ||= Resources::Products.new(@http_client)
    end

    # @return [Malipopay::Resources::Transactions]
    def transactions
      @transactions ||= Resources::Transactions.new(@http_client)
    end

    # @return [Malipopay::Resources::Account]
    def account
      @account ||= Resources::Account.new(@http_client)
    end

    # @return [Malipopay::Resources::Sms]
    def sms
      @sms ||= Resources::Sms.new(@http_client)
    end

    # @return [Malipopay::Resources::References]
    def references
      @references ||= Resources::References.new(@http_client)
    end

    # @return [Malipopay::Webhooks::Verifier]
    # @raise [ArgumentError] if webhook_secret was not provided
    def webhooks
      raise ArgumentError, "webhook_secret is required for webhook verification" unless @webhook_secret

      @webhooks ||= Webhooks::Verifier.new(@webhook_secret)
    end
  end
end
