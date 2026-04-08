# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conditioning, type: :model do
  before do
    Conditioning.delete_all
    Sauce.delete_all
    Category.delete_all
  end

  describe "valid conditioning" do
    it "persists a conditioning with volume, price, and sauce" do
      conditioning = build_conditioning
      expect(conditioning.save).to be true
      conditioning.reload
      expect(conditioning.volume).to eq("250ml")
      expect(conditioning.price).to eq(BigDecimal("6.9"))
      expect(conditioning.sauce).to be_present
    end
  end

  describe "volume" do
    it "rejects blank volume" do
      conditioning = build_conditioning(volume: "")
      expect(conditioning.save).to be false
      expect(conditioning.errors[:volume]).to be_present
    end

    it "rejects volume longer than 20 characters" do
      conditioning = build_conditioning(volume: "a" * 21)
      expect(conditioning.save).to be false
      expect(conditioning.errors[:volume]).to be_present
    end

    it "accepts volume exactly 20 characters" do
      conditioning = build_conditioning(volume: "a" * 20)
      expect(conditioning.save).to be true
      expect(conditioning.reload.volume.length).to eq(20)
    end
  end

  describe "price" do
    it "rejects blank price" do
      conditioning = build_conditioning(price: nil)
      expect(conditioning.save).to be false
      expect(conditioning.errors[:price]).to be_present
    end

    it "rejects negative price" do
      conditioning = build_conditioning(price: -0.01)
      expect(conditioning.save).to be false
      expect(conditioning.errors[:price]).to be_present
    end

    it "accepts zero price" do
      conditioning = build_conditioning(price: 0)
      expect(conditioning.save).to be true
      expect(conditioning.reload.price).to eq(0)
    end

    it "accepts a positive decimal price" do
      conditioning = build_conditioning(price: BigDecimal("12.99"))
      expect(conditioning.save).to be true
      expect(conditioning.reload.price).to eq(BigDecimal("12.99"))
    end
  end

  describe "associations" do
    it "belongs to a sauce" do
      sauce = create_sauce!
      conditioning = described_class.create!(volume: "500ml", price: 4.5, sauce: sauce)

      expect(conditioning.sauce).to eq(sauce)
      expect(sauce.conditionings).to include(conditioning)
    end

    it "rejects save without a sauce" do
      conditioning = described_class.new(volume: "250ml", price: 6.90)
      expect(conditioning.save).to be false
      expect(conditioning.errors[:sauce]).to be_present
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
      volume: "250ml",
      price: 6.90,
      sauce: create_sauce!
    }.merge(overrides)
  end

  def build_conditioning(overrides = {})
    described_class.new(valid_attributes(overrides))
  end
end
