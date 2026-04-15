# frozen_string_literal: true

module Malipopay
  module Resources
    class References
      def initialize(http_client)
        @http = http_client
      end

      # List all supported banks
      # @param params [Hash] Query parameters
      # @return [Hash] List of banks
      def banks(params = {})
        @http.get("/api/v1/standard/banks", params: params)
      end

      # List all supported financial institutions
      # @param params [Hash] Query parameters
      # @return [Hash] List of institutions
      def institutions(params = {})
        @http.get("/api/v1/standard/institutions", params: params)
      end

      # List all supported currencies
      # @param params [Hash] Query parameters
      # @return [Hash] List of currencies
      def currencies(params = {})
        @http.get("/api/v1/standard/currency", params: params)
      end

      # List all supported countries
      # @param params [Hash] Query parameters
      # @return [Hash] List of countries
      def countries(params = {})
        @http.get("/api/v1/standard/countries", params: params)
      end

      # List business types
      # @param params [Hash] Query parameters
      # @return [Hash] List of business types
      def business_types(params = {})
        @http.get("/api/v1/standard/businessType", params: params)
      end
    end
  end
end
