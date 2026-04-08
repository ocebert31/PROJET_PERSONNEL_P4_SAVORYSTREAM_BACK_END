# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stock, type: :model do
  before do
    Stock.delete_all
    Ingredient.delete_all
    Conditioning.delete_all
    Sauce.delete_all
    Category.delete_all
  end

  describe "valid stock" do
    it "persists a stock with quantity and sauce" do
      stock = build_stock
      expect(stock.save).to be true
      stock.reload
      expect(stock.quantity).to eq(12)
      expect(stock.sauce).to be_present
    end
  end

  describe "quantity" do
    it "rejects blank quantity" do
      stock = build_stock(quantity: nil)
      expect(stock.save).to be false
      expect(stock.errors[:quantity]).to be_present
    end

    it "rejects non-integer quantity" do
      stock = build_stock(quantity: 1.5)
      expect(stock.save).to be false
      expect(stock.errors[:quantity]).to be_present
    end

    it "rejects negative quantity" do
      stock = build_stock(quantity: -1)
      expect(stock.save).to be false
      expect(stock.errors[:quantity]).to be_present
    end

    it "accepts zero quantity" do
      stock = build_stock(quantity: 0)
      expect(stock.save).to be true
      expect(stock.reload.quantity).to eq(0)
    end

    it "accepts a positive integer quantity" do
      stock = build_stock(quantity: 999)
      expect(stock.save).to be true
      expect(stock.reload.quantity).to eq(999)
    end
  end

  describe "associations" do
    it "belongs to a sauce" do
      sauce = create_sauce!
      stock = described_class.create!(quantity: 7, sauce: sauce)

      expect(stock.sauce).to eq(sauce)
      expect(sauce.stock).to eq(stock)
    end

    it "rejects save without a sauce" do
      stock = described_class.new(quantity: 5)
      expect(stock.save).to be false
      expect(stock.errors[:sauce]).to be_present
    end

    it "does not allow a second stock for the same sauce" do
      sauce = create_sauce!
      described_class.create!(quantity: 5, sauce: sauce)

      duplicate = described_class.new(quantity: 10, sauce: sauce)
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
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
      quantity: 12,
      sauce: create_sauce!
    }.merge(overrides)
  end

  def build_stock(overrides = {})
    described_class.new(valid_attributes(overrides))
  end
end
