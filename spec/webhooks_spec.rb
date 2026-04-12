# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe MaliPoPay::Webhooks::Verifier do
  let(:secret) { "whsec_test_secret_key" }
  let(:verifier) { described_class.new(secret) }
  let(:payload) { '{"event":"payment.completed","data":{"reference":"PAY-123"}}' }
  let(:timestamp) { Time.now.to_i.to_s }

  describe ".sign" do
    it "generates an HMAC-SHA256 signature" do
      signature = described_class.sign(payload, secret)
      expect(signature).to be_a(String)
      expect(signature.length).to eq(64) # hex-encoded SHA256
    end

    it "includes timestamp in signature when provided" do
      sig_without = described_class.sign(payload, secret)
      sig_with = described_class.sign(payload, secret, timestamp: timestamp)
      expect(sig_without).not_to eq(sig_with)
    end

    it "produces consistent signatures for the same input" do
      sig1 = described_class.sign(payload, secret)
      sig2 = described_class.sign(payload, secret)
      expect(sig1).to eq(sig2)
    end
  end

  describe "#verify" do
    it "returns true for a valid signature" do
      signature = described_class.sign(payload, secret)
      expect(verifier.verify(payload, signature)).to be true
    end

    it "returns true for a valid signature with timestamp" do
      signature = described_class.sign(payload, secret, timestamp: timestamp)
      expect(verifier.verify(payload, signature, timestamp: timestamp)).to be true
    end

    it "returns false for an invalid signature" do
      expect(verifier.verify(payload, "invalid_signature")).to be false
    end

    it "returns false for a nil signature" do
      expect(verifier.verify(payload, nil)).to be false
    end

    it "returns false for an empty signature" do
      expect(verifier.verify(payload, "")).to be false
    end

    it "returns false for an expired timestamp" do
      old_timestamp = (Time.now.to_i - 600).to_s # 10 minutes ago
      signature = described_class.sign(payload, secret, timestamp: old_timestamp)
      expect(verifier.verify(payload, signature, timestamp: old_timestamp)).to be false
    end
  end

  describe "#construct_event" do
    it "returns parsed JSON for a valid signature" do
      signature = described_class.sign(payload, secret)
      event = verifier.construct_event(payload, signature)
      expect(event).to be_a(Hash)
      expect(event["event"]).to eq("payment.completed")
      expect(event["data"]["reference"]).to eq("PAY-123")
    end

    it "raises AuthenticationError for an invalid signature" do
      expect {
        verifier.construct_event(payload, "bad_signature")
      }.to raise_error(MaliPoPay::AuthenticationError, "Invalid webhook signature")
    end
  end
end
