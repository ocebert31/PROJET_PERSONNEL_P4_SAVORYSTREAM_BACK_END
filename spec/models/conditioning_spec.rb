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
      conditioning = build(:conditioning, volume: "250ml", price: 6.90)

      expect(conditioning.save).to be true
      conditioning.reload
      expect(conditioning.volume).to eq("250ml")
      expect(conditioning.price_ttc_cents).to eq(690)
      expect(conditioning.price).to eq(BigDecimal("6.9"))
      expect(conditioning.sauce).to be_present
    end
  end

  describe "volume" do
    it "rejects blank volume" do
      conditioning = build(:conditioning, volume: "")
      expect(conditioning.save).to be false
      expect(conditioning.errors[:volume]).to be_present
    end

    it "rejects volume longer than 20 characters" do
      conditioning = build(:conditioning, volume: "a" * 21)
      expect(conditioning.save).to be false
      expect(conditioning.errors[:volume]).to be_present
    end

    it "accepts volume exactly 20 characters" do
      conditioning = build(:conditioning, volume: "a" * 20)
      expect(conditioning.save).to be true
      expect(conditioning.reload.volume.length).to eq(20)
    end
  end

  describe "#price" do
    it "returns nil when price_ttc_cents is nil" do
      conditioning = described_class.new

      expect(conditioning.price).to be_nil
    end

    it "converts stored cents to euros as BigDecimal" do
      conditioning = described_class.new(price_ttc_cents: 999)

      expect(conditioning.price).to eq(BigDecimal("9.99"))
    end

    it "returns zero when price_ttc_cents is 0" do
      conditioning = described_class.new(price_ttc_cents: 0)

      expect(conditioning.price).to eq(BigDecimal("0"))
    end

    it "reads back a value set via price=" do
      conditioning = described_class.new
      conditioning.price = "6.90"

      expect(conditioning.price).to eq(BigDecimal("6.9"))
      expect(conditioning.price_ttc_cents).to eq(690)
    end
  end

  describe "#price=" do
    it "sets price_ttc_cents to nil when value is nil" do
      conditioning = described_class.new(price_ttc_cents: 500)
      conditioning.price = nil

      expect(conditioning.price_ttc_cents).to be_nil
    end

    it "sets price_ttc_cents to nil when value is blank" do
      conditioning = described_class.new(price_ttc_cents: 500)
      conditioning.price = ""

      expect(conditioning.price_ttc_cents).to be_nil
    end

    it "converts a string euro amount to cents" do
      conditioning = described_class.new
      conditioning.price = "9.99"

      expect(conditioning.price_ttc_cents).to eq(999)
    end

    it "converts a float euro amount to cents" do
      conditioning = described_class.new
      conditioning.price = 5.90

      expect(conditioning.price_ttc_cents).to eq(590)
    end

    it "converts an integer euro amount to cents" do
      conditioning = described_class.new
      conditioning.price = 10

      expect(conditioning.price_ttc_cents).to eq(1000)
    end

    it "converts a BigDecimal euro amount to cents" do
      conditioning = described_class.new
      conditioning.price = BigDecimal("12.99")

      expect(conditioning.price_ttc_cents).to eq(1299)
    end

    it "rounds fractional cents to the nearest integer cent" do
      conditioning = described_class.new
      conditioning.price = "9.994"

      expect(conditioning.price_ttc_cents).to eq(999)

      conditioning.price = "9.995"

      expect(conditioning.price_ttc_cents).to eq(1000)
    end

    it "sets price_ttc_cents to nil when value is not numeric" do
      conditioning = described_class.new(price_ttc_cents: 100)
      conditioning.price = "not-a-price"

      expect(conditioning.price_ttc_cents).to be_nil
    end
  end

  describe "price validations" do
    it "rejects blank price" do
      conditioning = build(:conditioning, price: nil)
      expect(conditioning.save).to be false
      expect(conditioning.errors[:price_ttc_cents]).to be_present
    end

    it "rejects negative price" do
      conditioning = build(:conditioning, price: -0.01)
      expect(conditioning.save).to be false
      expect(conditioning.errors[:price_ttc_cents]).to be_present
    end

    it "accepts zero price" do
      conditioning = build(:conditioning, price: 0)
      expect(conditioning.save).to be true
      expect(conditioning.reload.price).to eq(0)
    end

    it "accepts a positive decimal price" do
      conditioning = build(:conditioning, price: BigDecimal("12.99"))
      expect(conditioning.save).to be true
      expect(conditioning.reload.price).to eq(BigDecimal("12.99"))
    end

    it "persists 9.99 EUR TTC as 999 in price_ttc_cents" do
      conditioning = build(:conditioning, price: "9.99")
      expect(conditioning.save).to be true
      expect(conditioning.reload.price_ttc_cents).to eq(999)
    end
  end

  describe "associations" do
    it "belongs to a sauce" do
      sauce = create(:sauce)
      conditioning = create(:conditioning, volume: "500ml", price: 4.5, sauce: sauce)

      expect(conditioning.sauce).to eq(sauce)
      expect(sauce.conditionings).to include(conditioning)
    end

    it "rejects save without a sauce" do
      conditioning = build(:conditioning, sauce: nil)
      expect(conditioning.save).to be false
      expect(conditioning.errors[:sauce]).to be_present
    end
  end
end
