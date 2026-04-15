# frozen_string_literal: true

module Malipopay
  module Resources
    class Invoices
      def initialize(http_client)
        @http = http_client
      end

      # Create a new invoice
      # @param params [Hash] Invoice parameters
      # @return [Hash] Created invoice
      def create(params)
        @http.post("/api/v1/invoice", body: params)
      end

      # List all invoices
      # @param params [Hash] Query parameters (page, limit, status, etc.)
      # @return [Hash] Paginated list of invoices
      def list(params = {})
        @http.get("/api/v1/invoice", params: params)
      end

      # Get an invoice by ID
      # @param id [String] Invoice ID
      # @return [Hash] Invoice details
      def get(id)
        @http.get("/api/v1/invoice/#{id}")
      end

      # Get an invoice by invoice number
      # @param number [String] Invoice number
      # @return [Hash] Invoice details
      def get_by_number(number)
        @http.get("/api/v1/invoice", params: { invoiceNumber: number })
      end

      # Update an existing invoice
      # @param id [String] Invoice ID
      # @param params [Hash] Updated invoice parameters
      # @return [Hash] Updated invoice
      def update(id, params)
        @http.put("/api/v1/invoice/#{id}", body: params)
      end

      # Record a payment against an invoice
      # @param params [Hash] Payment parameters (invoiceId, amount, reference, etc.)
      # @return [Hash] Payment record response
      def record_payment(params)
        @http.post("/api/v1/invoice/record-payment", body: params)
      end

      # Approve a draft invoice
      # @param params [Hash] Approval parameters (invoiceId, etc.)
      # @return [Hash] Approval response
      def approve_draft(params)
        @http.post("/api/v1/invoice/approve-draft", body: params)
      end
    end
  end
end
