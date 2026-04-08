# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::ConditioningSerializer do
  describe ".call" do
    it "returns the nominal payload for a conditioning" do
      sauce = create(:sauce)
      conditioning = create(:conditioning, sauce: sauce, volume: "500ml", price: 12.5)

      json = described_class.call(conditioning)

      expect(json).to eq(
        id: conditioning.id,
        volume: "500ml",
        price: conditioning.price.to_s,
        sauce_id: sauce.id,
        created_at: conditioning.created_at,
        updated_at: conditioning.updated_at
      )
    end
  end
end
