# frozen_string_literal: true

module MaliPoPay
  module Resources
    class Payments
      def initialize(http_client)
        @http = http_client
      end

      # Initiate a payment (collection or disbursement)
      # @param params [Hash] Payment parameters
      # @return [Hash] Payment response
      def initiate(params)
        @http.post("/api/v1/payment", body: params)
      end

      # Initiate a mobile money collection
      # @param params [Hash] Collection parameters (amount, phone, provider, reference, etc.)
      # @return [Hash] Collection response
      def collect(params)
        @http.post("/api/v1/payment/collection", body: params)
      end

      # Initiate a disbursement (send money)
      # @param params [Hash] Disbursement parameters
      # @return [Hash] Disbursement response
      def disburse(params)
        @http.post("/api/v1/payment/disbursement", body: params)
      end

      # Process an instant payment
      # @param params [Hash] Payment parameters
      # @return [Hash] Payment response
      def pay_now(params)
        @http.post("/api/v1/payment/now", body: params)
      end

      # Verify a payment by reference
      # @param reference [String] Payment reference
      # @return [Hash] Payment verification details
      def verify(reference)
        @http.get("/api/v1/payment/verify/#{reference}")
      end

      # Get a payment by reference
      # @param reference [String] Payment reference
      # @return [Hash] Payment details
      def get(reference)
        @http.get("/api/v1/payment/reference/#{reference}")
      end

      # List all payments
      # @param params [Hash] Query parameters (page, limit, etc.)
      # @return [Hash] Paginated list of payments
      def list(params = {})
        @http.get("/api/v1/payment", params: params)
      end

      # Search payments
      # @param params [Hash] Search parameters
      # @return [Hash] Search results
      def search(params = {})
        @http.get("/api/v1/payment/search", params: params)
      end

      # Approve a pending payment
      # @param params [Hash] Approval parameters (reference, etc.)
      # @return [Hash] Approval response
      def approve(params)
        @http.post("/api/v1/payment/approve", body: params)
      end

      # Retry a failed collection
      # @param reference [String] Payment reference to retry
      # @return [Hash] Retry response
      def retry_collection(reference)
        @http.get("/api/v1/payment/retry/#{reference}")
      end

      # Create a payment link
      # @param params [Hash] Payment link parameters
      # @return [Hash] Payment link response
      def create_link(params)
        @http.post("/api/v1/pay", body: params)
      end
    end
  end
end
