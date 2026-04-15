# frozen_string_literal: true

require_relative "malipopay/version"
require_relative "malipopay/errors"
require_relative "malipopay/http_client"
require_relative "malipopay/client"

# Resources
require_relative "malipopay/resources/payments"
require_relative "malipopay/resources/customers"
require_relative "malipopay/resources/invoices"
require_relative "malipopay/resources/products"
require_relative "malipopay/resources/transactions"
require_relative "malipopay/resources/account"
require_relative "malipopay/resources/sms"
require_relative "malipopay/resources/references"

# Webhooks
require_relative "malipopay/webhooks/verifier"

module Malipopay
  # Convenience method to create a new client
  #
  # @param options [Hash] Options passed to Malipopay::Client.new
  # @return [Malipopay::Client]
  def self.client(**options)
    Client.new(**options)
  end
end
