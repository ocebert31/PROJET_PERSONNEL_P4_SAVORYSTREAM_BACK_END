# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::CategorySerializer do
  describe ".call" do
    it "returns the nominal payload for a category" do
      category = create(:category, name: "Condiments")

      json = described_class.call(category)

      expect(json).to eq(
        id: category.id,
        name: "Condiments",
        created_at: category.created_at,
        updated_at: category.updated_at
      )
    end
  end
end
