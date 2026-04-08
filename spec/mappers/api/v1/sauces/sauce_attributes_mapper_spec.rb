# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::SauceAttributesMapper do
  def permit_params(hash)
    ActionController::Parameters.new(hash).permit(
      :name, :tagline, :description, :characteristic, :image_url, :is_available, :category_id,
      :imageUrl, :isAvailable, :categoryId,
      stock: [ :quantity ],
      conditionings: [ :volume, :price ],
      ingredients: [ :name, :quantity ]
    )
  end

  def map(raw)
    described_class.call(permit_params(raw))
  end

  describe ".call" do
    it "matches new(permitted).to_model_attributes" do
      permitted = permit_params(name: "Sriracha")
      expect(described_class.call(permitted)).to eq(described_class.new(permitted).to_model_attributes)
    end
  end

  describe "#to_model_attributes" do
    it "returns an empty hash when there is nothing to map" do
      expect(map({})).to eq({})
    end

    it "maps scalar fields when keys are present and omits absent keys" do
      expect(map(name: "N", tagline: "T", description: "D", characteristic: "C")).to eq(
        name: "N", tagline: "T", description: "D", characteristic: "C"
      )
      expect(map(name: "Only")).to eq(name: "Only")
    end

    it "resolves image_url from snake_case, camelCase, prefers non-blank snake_case, and falls back when blank" do
      expect(map(image_url: "https://a")).to eq(image_url: "https://a")
      expect(map(imageUrl: "https://b")).to eq(image_url: "https://b")
      expect(map(image_url: "https://first", imageUrl: "https://second")[:image_url]).to eq("https://first")
      expect(map(image_url: "", imageUrl: "https://fallback")[:image_url]).to eq("https://fallback")
    end

    it "casts is_available from strings, camelCase, boolean false, and blank string + camel fallback" do
      expect(map(is_available: "true")[:is_available]).to be true
      expect(map(is_available: "false")[:is_available]).to be false
      expect(map(isAvailable: "1")[:is_available]).to be true
      expect(map(is_available: false)[:is_available]).to be false
      expect(map(is_available: "", isAvailable: "true")[:is_available]).to be true
    end

    it "maps category_id from snake_case or camelCase and omits it when blank" do
      id = SecureRandom.uuid
      expect(map(category_id: id)).to eq(category_id: id)
      expect(map(categoryId: id)).to eq(category_id: id)
      expect(map(category_id: "")).to eq({})
    end

    it "passes nested hashes as stock_attributes, conditionings_attributes, ingredients_attributes" do
      stock = map(stock: { quantity: 12 })
      expect(stock[:stock_attributes].to_unsafe_h).to eq("quantity" => 12)

      cond = map(conditionings: [ { volume: "250ml", price: "6.9" } ])
      expect(cond[:conditionings_attributes].first.to_unsafe_h).to eq("volume" => "250ml", "price" => "6.9")

      ing = map(ingredients: [ { name: "Piment", quantity: "30%" } ])
      expect(ing[:ingredients_attributes].first.to_unsafe_h).to eq("name" => "Piment", "quantity" => "30%")
    end

    it "maps a combined payload (camelCase + nested) in one pass" do
      category_id = SecureRandom.uuid
      attrs = map(
        name: "Full",
        tagline: "T",
        description: "D",
        characteristic: "C",
        imageUrl: "https://img",
        isAvailable: "true",
        categoryId: category_id,
        stock: { quantity: 5 },
        conditionings: [ { volume: "500ml", price: "9.99" } ],
        ingredients: [ { name: "Sel", quantity: "1%" } ]
      )

      expect(attrs).to include(
        name: "Full",
        tagline: "T",
        description: "D",
        characteristic: "C",
        image_url: "https://img",
        is_available: true,
        category_id: category_id
      )
      expect(attrs[:stock_attributes]).to be_present
      expect(attrs[:conditionings_attributes]).to be_present
      expect(attrs[:ingredients_attributes]).to be_present
    end
  end
end
