# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::IngredientParameters do
  def ac_params(hash)
    ActionController::Parameters.new(hash)
  end

  describe "#permitted" do
    it "permits name, quantity, and sauce_id for a typical payload" do
      permitted = described_class.new(
        ac_params(name: "Piment", quantity: "30%", sauce_id: SecureRandom.uuid)
      ).permitted

      expect(permitted.to_unsafe_h.keys).to contain_exactly("name", "quantity", "sauce_id")
      expect(permitted[:name]).to eq("Piment")
    end

    it "drops keys that are not explicitly allowed" do
      permitted = described_class.new(
        ac_params(name: "Sel", quantity: "1%", sauce_id: "uuid", injected: "bad")
      ).permitted

      expect(permitted[:injected]).to be_nil
    end
  end
end
