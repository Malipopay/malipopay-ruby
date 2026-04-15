# frozen_string_literal: true

module Malipopay
  module Resources
    class Customers
      def initialize(http_client)
        @http = http_client
      end

      # Create a new customer
      # @param params [Hash] Customer parameters (name, phone, email, etc.)
      # @return [Hash] Created customer
      def create(params)
        @http.post("/api/v1/customer", body: params)
      end

      # List all customers
      # @param params [Hash] Query parameters (page, limit, etc.)
      # @return [Hash] Paginated list of customers
      def list(params = {})
        @http.get("/api/v1/customer", params: params)
      end

      # Get a customer by ID
      # @param id [String] Customer ID
      # @return [Hash] Customer details
      def get(id)
        @http.get("/api/v1/customer/#{id}")
      end

      # Get a customer by customer number
      # @param number [String] Customer number
      # @return [Hash] Customer details
      def get_by_number(number)
        @http.get("/api/v1/customer/search", params: { customerNumber: number })
      end

      # Get a customer by phone number
      # @param phone [String] Phone number
      # @return [Hash] Customer details
      def get_by_phone(phone)
        @http.get("/api/v1/customer/search", params: { phone: phone })
      end

      # Search customers
      # @param params [Hash] Search parameters
      # @return [Hash] Search results
      def search(params = {})
        @http.get("/api/v1/customer/search", params: params)
      end

      # Verify a customer
      # @param params [Hash] Verification parameters
      # @return [Hash] Verification response
      def verify_customer(params)
        @http.post("/api/v1/customer/verify", body: params)
      end
    end
  end
end
