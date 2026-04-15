#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Webhook handler for Malipopay events
#
# This example uses Sinatra. Install it with:
#   gem install sinatra
#
# Usage:
#   MALIPOPAY_API_KEY=your_key MALIPOPAY_WEBHOOK_SECRET=your_secret ruby examples/webhook_handler.rb

require "sinatra"
require "malipopay"

client = Malipopay::Client.new(
  api_key: ENV.fetch("MALIPOPAY_API_KEY"),
  webhook_secret: ENV.fetch("MALIPOPAY_WEBHOOK_SECRET")
)

post "/webhooks/malipopay" do
  payload = request.body.read
  signature = request.env["HTTP_X_MALIPOPAY_SIGNATURE"]
  timestamp = request.env["HTTP_X_MALIPOPAY_TIMESTAMP"]

  begin
    event = client.webhooks.construct_event(payload, signature, timestamp: timestamp)

    case event["event"]
    when "payment.completed"
      handle_payment_completed(event["data"])
    when "payment.failed"
      handle_payment_failed(event["data"])
    when "invoice.paid"
      handle_invoice_paid(event["data"])
    else
      puts "Unhandled event type: #{event['event']}"
    end

    status 200
    json({ received: true })
  rescue Malipopay::AuthenticationError => e
    status 401
    json({ error: e.message })
  rescue JSON::ParserError
    status 400
    json({ error: "Invalid payload" })
  end
end

def handle_payment_completed(data)
  puts "Payment completed!"
  puts "  Reference: #{data['reference']}"
  puts "  Amount: #{data['amount']} #{data['currency']}"
  puts "  Phone: #{data['phone']}"
  # Update your database, send confirmation, etc.
end

def handle_payment_failed(data)
  puts "Payment failed!"
  puts "  Reference: #{data['reference']}"
  puts "  Reason: #{data['reason']}"
  # Handle failure, notify customer, etc.
end

def handle_invoice_paid(data)
  puts "Invoice paid!"
  puts "  Invoice: #{data['invoiceNumber']}"
  puts "  Amount: #{data['amount']}"
  # Update invoice status in your system
end
