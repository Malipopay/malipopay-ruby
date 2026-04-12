# frozen_string_literal: true

module MaliPoPay
  module Resources
    class Products
      def initialize(http_client)
        @http = http_client
      end

      # Create a new product
      # @param params [Hash] Product parameters (name, price, description, etc.)
      # @return [Hash] Created product
      def create(params)
        @http.post("/api/v1/product", body: params)
      end

      # List all products
      # @param params [Hash] Query parameters (page, limit, etc.)
      # @return [Hash] Paginated list of products
      def list(params = {})
        @http.get("/api/v1/product", params: params)
      end

      # Get a product by ID
      # @param id [String] Product ID
      # @return [Hash] Product details
      def get(id)
        @http.get("/api/v1/product/#{id}")
      end

      # Get a product by product number
      # @param number [String] Product number
      # @return [Hash] Product details
      def get_by_number(number)
        @http.get("/api/v1/product", params: { productNumber: number })
      end

      # Update an existing product
      # @param id [String] Product ID
      # @param params [Hash] Updated product parameters
      # @return [Hash] Updated product
      def update(id, params)
        @http.put("/api/v1/product/#{id}", body: params)
      end
    end
  end
end
