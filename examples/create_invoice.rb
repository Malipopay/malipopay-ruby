#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Create and manage invoices via MaliPoPay
#
# Usage:
#   MALIPOPAY_API_KEY=your_key ruby examples/create_invoice.rb

require "malipopay"

client = MaliPoPay::Client.new(
  api_key: ENV.fetch("MALIPOPAY_API_KEY"),
  environment: :uat
)

begin
  # Create a customer first
  customer = client.customers.create(
    name: "John Doe",
    phone: "255712345678",
    email: "john@example.com"
  )
  puts "Customer created: #{customer['id']}"

  # Create an invoice
  invoice = client.invoices.create(
    customerId: customer["id"],
    items: [
      { description: "Web Development", quantity: 1, unitPrice: 500_000 },
      { description: "Hosting (12 months)", quantity: 12, unitPrice: 25_000 }
    ],
    currency: "TZS",
    dueDate: (Time.now + 30 * 24 * 3600).strftime("%Y-%m-%d"),
    notes: "Payment due within 30 days"
  )
  puts "Invoice created: #{invoice['invoiceNumber']}"
  puts "Total: TZS #{invoice['total']}"

  # Approve the draft invoice
  approved = client.invoices.approve_draft(invoiceId: invoice["id"])
  puts "Invoice approved: #{approved['status']}"

  # Record a partial payment
  payment = client.invoices.record_payment(
    invoiceId: invoice["id"],
    amount: 250_000,
    reference: "RCPT-#{Time.now.to_i}",
    method: "mobile_money"
  )
  puts "Payment recorded: #{payment['reference']}"

  # List all invoices
  invoices = client.invoices.list(page: 1, limit: 10)
  puts "Total invoices: #{invoices['total']}"
rescue MaliPoPay::Error => e
  puts "Error: #{e.message} (HTTP #{e.http_status})"
end
