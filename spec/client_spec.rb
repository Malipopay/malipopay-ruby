# frozen_string_literal: true

require "spec_helper"

RSpec.describe MaliPoPay::Client do
  let(:api_key) { "test_api_key_123" }

  describe "#initialize" do
    it "creates a client with required api_key" do
      client = described_class.new(api_key: api_key)
      expect(client).to be_a(MaliPoPay::Client)
    end

    it "raises ArgumentError when api_key is nil" do
      expect { described_class.new(api_key: nil) }.to raise_error(ArgumentError, "api_key is required")
    end

    it "raises ArgumentError when api_key is empty" do
      expect { described_class.new(api_key: "") }.to raise_error(ArgumentError, "api_key is required")
    end

    it "defaults to production environment" do
      client = described_class.new(api_key: api_key)
      expect(client.http_client).to be_a(MaliPoPay::HttpClient)
    end

    it "accepts uat environment" do
      client = described_class.new(api_key: api_key, environment: :uat)
      expect(client).to be_a(MaliPoPay::Client)
    end

    it "accepts a custom base_url" do
      client = described_class.new(api_key: api_key, base_url: "https://custom.example.com")
      expect(client).to be_a(MaliPoPay::Client)
    end

    it "stores the webhook_secret" do
      client = described_class.new(api_key: api_key, webhook_secret: "whsec_test")
      expect(client.webhook_secret).to eq("whsec_test")
    end
  end

  describe "resource accessors" do
    let(:client) { described_class.new(api_key: api_key) }

    it "returns a Payments resource" do
      expect(client.payments).to be_a(MaliPoPay::Resources::Payments)
    end

    it "returns a Customers resource" do
      expect(client.customers).to be_a(MaliPoPay::Resources::Customers)
    end

    it "returns an Invoices resource" do
      expect(client.invoices).to be_a(MaliPoPay::Resources::Invoices)
    end

    it "returns a Products resource" do
      expect(client.products).to be_a(MaliPoPay::Resources::Products)
    end

    it "returns a Transactions resource" do
      expect(client.transactions).to be_a(MaliPoPay::Resources::Transactions)
    end

    it "returns an Account resource" do
      expect(client.account).to be_a(MaliPoPay::Resources::Account)
    end

    it "returns an Sms resource" do
      expect(client.sms).to be_a(MaliPoPay::Resources::Sms)
    end

    it "returns a References resource" do
      expect(client.references).to be_a(MaliPoPay::Resources::References)
    end

    it "memoizes resource instances" do
      expect(client.payments).to equal(client.payments)
    end

    it "returns a Webhooks verifier when secret is provided" do
      client = described_class.new(api_key: api_key, webhook_secret: "whsec_test")
      expect(client.webhooks).to be_a(MaliPoPay::Webhooks::Verifier)
    end

    it "raises when accessing webhooks without a secret" do
      expect { client.webhooks }.to raise_error(ArgumentError, /webhook_secret is required/)
    end
  end

  describe ".client convenience method" do
    it "creates a client via MaliPoPay.client" do
      client = MaliPoPay.client(api_key: api_key)
      expect(client).to be_a(MaliPoPay::Client)
    end
  end
end
