# frozen_string_literal: true

module MaliPoPay
  module Resources
    class Transactions
      def initialize(http_client)
        @http = http_client
      end

      # List all transactions
      # @param params [Hash] Query parameters (page, limit, type, status, etc.)
      # @return [Hash] Paginated list of transactions
      def list(params = {})
        @http.get("/api/v1/transactions", params: params)
      end

      # Get a transaction by ID
      # @param id [String] Transaction ID
      # @return [Hash] Transaction details
      def get(id)
        @http.get("/api/v1/transactions/#{id}")
      end

      # Search transactions
      # @param params [Hash] Search parameters (query, dateFrom, dateTo, etc.)
      # @return [Hash] Search results
      def search(params = {})
        @http.get("/api/v1/transactions/search", params: params)
      end

      # Paginate through transactions
      # @param params [Hash] Pagination parameters (page, limit)
      # @yield [Hash] Each page of transactions
      # @return [Enumerator] If no block given
      def paginate(params = {})
        return enum_for(:paginate, params) unless block_given?

        page = params.fetch(:page, 1)
        loop do
          result = list(params.merge(page: page))
          yield result

          records = result["data"] || result["records"] || []
          break if records.empty?

          page += 1
        end
      end

      # Get tariff information
      # @param params [Hash] Query parameters
      # @return [Hash] Tariff details
      def tariffs(params = {})
        @http.get("/api/v1/transactions", params: params.merge(type: "tariff"))
      end
    end
  end
end
