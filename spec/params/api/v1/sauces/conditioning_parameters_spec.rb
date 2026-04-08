# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::ConditioningParameters do
  def ac_params(hash)
    ActionController::Parameters.new(hash)
  end

  describe "#permitted" do
    it "permits volume, price, and sauce_id for a typical payload" do
      permitted = described_class.new(
        ac_params(volume: "250ml", price: "6.9", sauce_id: SecureRandom.uuid)
      ).permitted

      expect(permitted.to_unsafe_h.keys).to contain_exactly("volume", "price", "sauce_id")
      expect(permitted[:volume]).to eq("250ml")
    end

    it "drops keys that are not explicitly allowed" do
      permitted = described_class.new(
        ac_params(volume: "500ml", price: "4", sauce_id: "uuid", extra: "no")
      ).permitted

      expect(permitted[:extra]).to be_nil
    end
  end
end
