# frozen_string_literal: true

require "openssl"
require "json"

module MaliPoPay
  module Webhooks
    class Verifier
      TOLERANCE_IN_SECONDS = 300 # 5 minutes

      def initialize(secret)
        @secret = secret
      end

      # Verify a webhook signature
      # @param payload [String] Raw request body
      # @param signature [String] Signature from X-MaliPoPay-Signature header
      # @param timestamp [String, nil] Timestamp from X-MaliPoPay-Timestamp header
      # @return [Boolean] Whether the signature is valid
      def verify(payload, signature, timestamp: nil)
        return false if signature.nil? || signature.empty?

        if timestamp
          ts = timestamp.to_i
          return false if (Time.now.to_i - ts).abs > TOLERANCE_IN_SECONDS
        end

        expected = self.class.sign(payload, @secret, timestamp: timestamp)
        secure_compare(expected, signature)
      end

      # Verify and parse a webhook event
      # @param payload [String] Raw request body
      # @param signature [String] Signature from header
      # @param timestamp [String, nil] Timestamp from header
      # @return [Hash] Parsed event data
      # @raise [MaliPoPay::Error] If signature is invalid
      def construct_event(payload, signature, timestamp: nil)
        unless verify(payload, signature, timestamp: timestamp)
          raise MaliPoPay::AuthenticationError.new("Invalid webhook signature")
        end

        JSON.parse(payload)
      end

      # Generate an HMAC signature for a payload
      # @param payload [String] Raw payload string
      # @param secret [String] Webhook secret
      # @param timestamp [String, nil] Optional timestamp to include in signature
      # @return [String] Hex-encoded HMAC-SHA256 signature
      def self.sign(payload, secret, timestamp: nil)
        signed_payload = timestamp ? "#{timestamp}.#{payload}" : payload
        OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
      end

      private

      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack("C*")
        r = b.unpack("C*")
        result = 0
        l.zip(r) { |x, y| result |= x ^ y }
        result.zero?
      end
    end
  end
end
