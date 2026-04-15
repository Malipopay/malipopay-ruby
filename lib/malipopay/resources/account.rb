# frozen_string_literal: true

module Malipopay
  module Resources
    class Account
      def initialize(http_client)
        @http = http_client
      end

      # List all account transactions
      # @param params [Hash] Query parameters (page, limit, dateFrom, dateTo, etc.)
      # @return [Hash] Paginated list of account transactions
      def transactions(params = {})
        @http.get("/api/v1/account/allTransaction", params: params)
      end

      # Search account transactions
      # @param params [Hash] Search parameters
      # @return [Hash] Search results
      def search_transactions(params = {})
        @http.get("/api/v1/account/allTransaction", params: params)
      end

      # Get account reconciliation data
      # @param params [Hash] Query parameters (dateFrom, dateTo, etc.)
      # @return [Hash] Reconciliation data
      def reconciliation(params = {})
        @http.get("/api/v1/account/reconciliation", params: params)
      end

      # Get financial position report
      # @param params [Hash] Query parameters
      # @return [Hash] Financial position data
      def financial_position(params = {})
        @http.get("/api/v1/account/allTransaction", params: params.merge(report: "financial_position"))
      end

      # Get income statement
      # @param params [Hash] Query parameters
      # @return [Hash] Income statement data
      def income_statement(params = {})
        @http.get("/api/v1/account/allTransaction", params: params.merge(report: "income_statement"))
      end

      # Get general ledger
      # @param params [Hash] Query parameters
      # @return [Hash] General ledger data
      def general_ledger(params = {})
        @http.get("/api/v1/account/allTransaction", params: params.merge(report: "general_ledger"))
      end

      # Get trial balance
      # @param params [Hash] Query parameters
      # @return [Hash] Trial balance data
      def trial_balance(params = {})
        @http.get("/api/v1/account/allTransaction", params: params.merge(report: "trial_balance"))
      end
    end
  end
end
