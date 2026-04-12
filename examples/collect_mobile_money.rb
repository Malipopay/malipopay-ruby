#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Collect mobile money payment via MaliPoPay
#
# Usage:
#   MALIPOPAY_API_KEY=your_key ruby examples/collect_mobile_money.rb

require "malipopay"

client = MaliPoPay::Client.new(
  api_key: ENV.fetch("MALIPOPAY_API_KEY"),
  environment: :uat # Use :production for live transactions
)

# Initiate a mobile money collection
begin
  result = client.payments.collect(
    amount: 10_000,
    phone: "255712345678",
    provider: "Vodacom",
    reference: "ORDER-#{Time.now.to_i}",
    description: "Payment for Order #1234",
    currency: "TZS"
  )

  puts "Collection initiated!"
  puts "Reference: #{result['reference']}"
  puts "Status: #{result['status']}"

  # Verify the payment status
  verification = client.payments.verify(result["reference"])
  puts "Verification status: #{verification['status']}"
rescue MaliPoPay::ValidationError => e
  puts "Validation failed: #{e.message}"
  puts "Errors: #{e.errors}" if e.errors
rescue MaliPoPay::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue MaliPoPay::Error => e
  puts "Error: #{e.message} (HTTP #{e.http_status})"
end
