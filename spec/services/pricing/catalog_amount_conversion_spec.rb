# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pricing::CatalogAmountConversion do
  let(:usd_pricing) { { currency_iso: "USD", eur_multiplier: BigDecimal("1.08") } }

  describe ".convert_bigdecimal" do
    context "nominal case" do
      it "returns the EUR amount unchanged when catalog_pricing is blank" do
        expect(described_class.convert_bigdecimal(10, nil)).to eq(BigDecimal("10"))
        expect(described_class.convert_bigdecimal("9.99", {})).to eq(BigDecimal("9.99"))
      end

      it "multiplies by eur_multiplier and rounds to two decimal places" do
        expect(described_class.convert_bigdecimal(10, usd_pricing)).to eq(BigDecimal("10.8"))
        expect(described_class.convert_bigdecimal("9.99", usd_pricing)).to eq(BigDecimal("10.79"))
      end
    end

    context "edge cases" do
      it "rounds half up at the second decimal" do
        pricing = { currency_iso: "USD", eur_multiplier: BigDecimal("1") }

        expect(described_class.convert_bigdecimal("9.995", pricing)).to eq(BigDecimal("10"))
        expect(described_class.convert_bigdecimal("9.994", pricing)).to eq(BigDecimal("9.99"))
      end

      it "raises when eur_multiplier is zero or negative" do
        expect do
          described_class.convert_bigdecimal(10, { currency_iso: "USD", eur_multiplier: 0 })
        end.to raise_error(ArgumentError, "eur_multiplier must be positive")

        expect do
          described_class.convert_bigdecimal(10, { currency_iso: "USD", eur_multiplier: -1 })
        end.to raise_error(ArgumentError, "eur_multiplier must be positive")
      end
    end
  end

  describe ".convert_to_float" do
    context "nominal case" do
      it "returns unchanged float when catalog_pricing is blank" do
        expect(described_class.convert_to_float(6.5, nil)).to eq(6.5)
      end

      it "returns converted float when catalog_pricing is present" do
        expect(described_class.convert_to_float(10, usd_pricing)).to eq(10.8)
      end
    end
  end

  describe ".convert_to_string" do
    context "nominal case" do
      it "returns unchanged string when catalog_pricing is blank" do
        expect(described_class.convert_to_string(6.9, nil)).to eq("6.9")
      end

      it "returns converted string when catalog_pricing is present" do
        expect(described_class.convert_to_string(10, usd_pricing)).to eq("10.8")
      end
    end
  end
end
