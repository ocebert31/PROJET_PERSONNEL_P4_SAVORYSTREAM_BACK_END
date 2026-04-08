# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::SauceSerializer do
  describe ".call" do
    it "returns the nominal payload when the sauce has category, stock, conditionings, ingredients, and no Active Storage image" do
      category = create(:category, name: "Hot")
      sauce = create(
        :sauce,
        category: category,
        name: "Sriracha",
        tagline: "Spicy",
        description: "Thai style",
        characteristic: "Heat",
        image_url: "https://cdn.example.com/sauce.png",
        is_available: true
      )
      stock = create(:stock, sauce: sauce, quantity: 42)
      conditioning = create(:conditioning, sauce: sauce, volume: "250ml", price: 6.9)
      ingredient = create(:ingredient, sauce: sauce, name: "Chili", quantity: "12%")
      sauce.reload

      json = described_class.call(sauce, base_url: "https://api.example.com")

      expect(json[:id]).to eq(sauce.id)
      expect(json[:name]).to eq("Sriracha")
      expect(json[:tagline]).to eq("Spicy")
      expect(json[:description]).to eq("Thai style")
      expect(json[:characteristic]).to eq("Heat")
      expect(json[:image_url]).to eq("https://cdn.example.com/sauce.png")
      expect(json[:is_available]).to be true
      expect(json[:category]).to eq(id: category.id, name: "Hot")
      expect(json[:stock]).to eq(id: stock.id, quantity: 42)
      expect(json[:conditionings]).to eq(
        [ { id: conditioning.id, volume: "250ml", price: conditioning.price.to_s } ]
      )
      expect(json[:ingredients]).to eq(
        [ { id: ingredient.id, name: "Chili", quantity: "12%" } ]
      )
      expect(json[:created_at]).to eq(sauce.created_at)
      expect(json[:updated_at]).to eq(sauce.updated_at)
    end
  end
end
