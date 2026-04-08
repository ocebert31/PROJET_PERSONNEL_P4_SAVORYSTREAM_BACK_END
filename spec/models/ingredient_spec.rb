# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ingredient, type: :model do
  before do
    Ingredient.delete_all
    Sauce.delete_all
    Category.delete_all
  end

  describe "valid ingredient" do
    it "persists an ingredient with name, quantity, and sauce" do
      ingredient = build_ingredient
      expect(ingredient.save).to be true
      ingredient.reload
      expect(ingredient.name).to eq("Piment")
      expect(ingredient.quantity).to eq("30%")
      expect(ingredient.sauce).to be_present
    end
  end

  describe "name" do
    it "rejects blank name" do
      ingredient = build_ingredient(name: "")
      expect(ingredient.save).to be false
      expect(ingredient.errors[:name]).to be_present
    end

    it "rejects name longer than 100 characters" do
      ingredient = build_ingredient(name: "a" * 101)
      expect(ingredient.save).to be false
      expect(ingredient.errors[:name]).to be_present
    end

    it "accepts name exactly 100 characters" do
      ingredient = build_ingredient(name: "a" * 100)
      expect(ingredient.save).to be true
      expect(ingredient.reload.name.length).to eq(100)
    end
  end

  describe "quantity" do
    it "rejects blank quantity" do
      ingredient = build_ingredient(quantity: "")
      expect(ingredient.save).to be false
      expect(ingredient.errors[:quantity]).to be_present
    end

    it "rejects quantity longer than 100 characters" do
      ingredient = build_ingredient(quantity: "a" * 101)
      expect(ingredient.save).to be false
      expect(ingredient.errors[:quantity]).to be_present
    end

    it "accepts quantity exactly 100 characters" do
      ingredient = build_ingredient(quantity: "a" * 100)
      expect(ingredient.save).to be true
      expect(ingredient.reload.quantity.length).to eq(100)
    end
  end

  describe "associations" do
    it "belongs to a sauce" do
      sauce = create_sauce!
      ingredient = described_class.create!(name: "Sucre", quantity: "50g/L", sauce: sauce)

      expect(ingredient.sauce).to eq(sauce)
      expect(sauce.ingredients).to include(ingredient)
    end

    it "rejects save without a sauce" do
      ingredient = described_class.new(name: "Piment", quantity: "30%")
      expect(ingredient.save).to be false
      expect(ingredient.errors[:sauce]).to be_present
    end
  end

  def create_sauce!(overrides = {})
    category = Category.create!(name: "Piquantes")
    Sauce.create!(
      {
        name: "Sauce #{SecureRandom.hex(6)}",
        tagline: "Tagline for spec.",
        category: category,
        is_available: true
      }.merge(overrides)
    )
  end

  def valid_attributes(overrides = {})
    {
      name: "Piment",
      quantity: "30%",
      sauce: create_sauce!
    }.merge(overrides)
  end

  def build_ingredient(overrides = {})
    described_class.new(valid_attributes(overrides))
  end
end
