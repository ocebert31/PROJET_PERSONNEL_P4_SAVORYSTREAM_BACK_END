# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sauce, type: :model do
  before do
    Ingredient.delete_all
    Conditioning.delete_all
    Stock.delete_all
    Sauce.delete_all
    Category.delete_all
  end

  describe "valid sauce" do
    it "persists a sauce with name, tagline, category, and availability" do
      sauce = build_sauce
      expect(sauce.save).to be true
      sauce.reload
      expect(sauce.name).to eq("Sriracha Spec")
      expect(sauce.tagline).to eq("Hot and tasty.")
      expect(sauce.category).to be_present
      expect(sauce.is_available).to be true
    end
  end

  describe "name" do
    it "rejects blank name" do
      sauce = build_sauce(name: "")
      expect(sauce.save).to be false
      expect(sauce.errors[:name]).to be_present
    end

    it "rejects name longer than 50 characters" do
      sauce = build_sauce(name: "a" * 51)
      expect(sauce.save).to be false
      expect(sauce.errors[:name]).to be_present
    end

    it "accepts name exactly 50 characters" do
      sauce = build_sauce(name: "a" * 50)
      expect(sauce.save).to be true
      expect(sauce.reload.name.length).to eq(50)
    end

    it "rejects duplicate name" do
      category = create_category!
      described_class.create!(valid_attributes.merge(name: "UniqueSauceName", category: category))

      sauce = build_sauce(name: "UniqueSauceName", category: category)
      expect(sauce.save).to be false
      expect(sauce.errors[:name]).to be_present
    end
  end

  describe "tagline" do
    it "rejects blank tagline" do
      sauce = build_sauce(tagline: "")
      expect(sauce.save).to be false
      expect(sauce.errors[:tagline]).to be_present
    end

    it "rejects tagline longer than 120 characters" do
      sauce = build_sauce(tagline: "a" * 121)
      expect(sauce.save).to be false
      expect(sauce.errors[:tagline]).to be_present
    end

    it "accepts tagline exactly 120 characters" do
      sauce = build_sauce(tagline: "a" * 120)
      expect(sauce.save).to be true
      expect(sauce.reload.tagline.length).to eq(120)
    end
  end

  describe "characteristic" do
    it "accepts blank characteristic" do
      sauce = build_sauce(characteristic: "")
      expect(sauce.save).to be true
    end

    it "rejects characteristic longer than 255 characters" do
      sauce = build_sauce(characteristic: "a" * 256)
      expect(sauce.save).to be false
      expect(sauce.errors[:characteristic]).to be_present
    end

    it "accepts characteristic exactly 255 characters" do
      sauce = build_sauce(characteristic: "a" * 255)
      expect(sauce.save).to be true
      expect(sauce.reload.characteristic.length).to eq(255)
    end
  end

  describe "is_available" do
    it "accepts true" do
      sauce = build_sauce(is_available: true)
      expect(sauce.save).to be true
      expect(sauce.reload.is_available).to be true
    end

    it "accepts false" do
      sauce = build_sauce(is_available: false)
      expect(sauce.save).to be true
      expect(sauce.reload.is_available).to be false
    end

    it "persists with true when the attribute is omitted (schema default)" do
      category = create_category!
      sauce = described_class.new(
        name: "DefaultAvail #{SecureRandom.hex(4)}",
        tagline: "Tagline for default availability.",
        category: category
      )
      expect(sauce.save).to be true
      expect(sauce.reload.is_available).to be true
    end

    it "rejects nil when explicitly assigned" do
      category = create_category!
      sauce = described_class.new(
        name: "NilAvail #{SecureRandom.hex(4)}",
        tagline: "Tagline.",
        category: category,
        is_available: true
      )
      sauce.is_available = nil
      expect(sauce.save).to be false
      expect(sauce.errors[:is_available]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a category" do
      category = create_category!
      sauce = described_class.create!(
        name: "Sauce #{SecureRandom.hex(4)}",
        tagline: "Tagline for spec.",
        category: category,
        is_available: true
      )

      expect(sauce.category).to eq(category)
      expect(category.sauces).to include(sauce)
    end

    it "rejects save without a category" do
      sauce = described_class.new(
        name: "Orphan",
        tagline: "No category.",
        is_available: true
      )
      expect(sauce.save).to be false
      expect(sauce.errors[:category]).to be_present
    end

    it "has many conditionings" do
      sauce = described_class.create!(valid_attributes.merge(name: "Sauce #{SecureRandom.hex(4)}"))
      Conditioning.create!(volume: "250ml", price: 6.9, sauce: sauce)
      Conditioning.create!(volume: "500ml", price: 11.9, sauce: sauce)

      expect(sauce.conditionings.count).to eq(2)
      expect(sauce.conditionings.pluck(:volume)).to contain_exactly("250ml", "500ml")
    end

    it "has many ingredients" do
      sauce = described_class.create!(valid_attributes.merge(name: "Sauce #{SecureRandom.hex(4)}"))
      Ingredient.create!(name: "Piment", quantity: "30%", sauce: sauce)
      Ingredient.create!(name: "Vinaigre", quantity: "10%", sauce: sauce)

      expect(sauce.ingredients.count).to eq(2)
      expect(sauce.ingredients.pluck(:name)).to contain_exactly("Piment", "Vinaigre")
    end

    it "has one stock" do
      sauce = described_class.create!(valid_attributes.merge(name: "Sauce #{SecureRandom.hex(4)}"))
      stock = Stock.create!(quantity: 42, sauce: sauce)

      expect(sauce.stock).to eq(stock)
    end

    it "destroys dependent conditionings, ingredients, and stock when the sauce is destroyed" do
      sauce = described_class.create!(valid_attributes.merge(name: "Sauce #{SecureRandom.hex(4)}"))
      Conditioning.create!(volume: "250ml", price: 6.9, sauce: sauce)
      Ingredient.create!(name: "Sel", quantity: "1%", sauce: sauce)
      Stock.create!(quantity: 5, sauce: sauce)

      expect { sauce.destroy! }.not_to raise_error

      expect(Conditioning.find_by(sauce_id: sauce.id)).to be_nil
      expect(Ingredient.find_by(sauce_id: sauce.id)).to be_nil
      expect(Stock.find_by(sauce_id: sauce.id)).to be_nil
    end
  end

  def create_category!(overrides = {})
    Category.create!({ name: "Category #{SecureRandom.hex(4)}" }.merge(overrides))
  end

  def valid_attributes(overrides = {})
    {
      name: "Sriracha Spec",
      tagline: "Hot and tasty.",
      category: create_category!,
      is_available: true
    }.merge(overrides)
  end

  def build_sauce(overrides = {})
    described_class.new(valid_attributes(overrides))
  end
end
