# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::IngredientSerializer do
  describe ".call" do
    it "returns the nominal payload for an ingredient" do
      sauce = create(:sauce)
      ingredient = create(:ingredient, sauce: sauce, name: "Garlic", quantity: "5%")

      json = described_class.call(ingredient)

      expect(json).to eq(
        id: ingredient.id,
        name: "Garlic",
        quantity: "5%",
        sauce_id: sauce.id,
        created_at: ingredient.created_at,
        updated_at: ingredient.updated_at
      )
    end
  end
end
