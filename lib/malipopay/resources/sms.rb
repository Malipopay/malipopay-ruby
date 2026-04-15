# frozen_string_literal: true

module Malipopay
  module Resources
    class Sms
      def initialize(http_client)
        @http = http_client
      end

      # Send a single SMS
      # @param params [Hash] SMS parameters (to, message, senderId, etc.)
      # @return [Hash] SMS send response
      def send_sms(params)
        @http.post("/sms/", body: params)
      end

      # Send bulk SMS
      # @param params [Hash] Bulk SMS parameters (messages array, senderId, etc.)
      # @return [Hash] Bulk SMS response
      def send_bulk(params)
        @http.post("/sms/bulk", body: params)
      end

      # Schedule an SMS for later delivery
      # @param params [Hash] Schedule parameters (to, message, senderId, scheduledAt, etc.)
      # @return [Hash] Scheduled SMS response
      def schedule(params)
        @http.post("/sms/schedule", body: params)
      end
    end
  end
end
