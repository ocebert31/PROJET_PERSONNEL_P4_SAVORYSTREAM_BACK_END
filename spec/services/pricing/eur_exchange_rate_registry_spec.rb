# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pricing::EurExchangeRateRegistry do
  describe ".multiplier_from_eur" do
    it "returns 1 for EUR" do
      expect(described_class.multiplier_from_eur("EUR")).to eq(BigDecimal("1"))
    end

    it "returns the configured multiplier for USD", :aggregate_failures do
      expect(described_class.multiplier_from_eur("usd")).to eq(BigDecimal("1.08"))
    end

    it "supports integer rates in YAML (e.g. JPY)" do
      expect(described_class.multiplier_from_eur("JPY")).to eq(BigDecimal("165"))
    end

    it "raises KeyError when currency is absent from YAML" do
      expect do
        described_class.multiplier_from_eur("XXX")
      end.to raise_error(KeyError)
    end
  end

  describe ".multiplier_from_eur?" do
    it "is true only for currencies present in YAML" do
      expect(described_class.multiplier_from_eur?("EUR")).to be(true)
      expect(described_class.multiplier_from_eur?("ZZZ")).to be(false)
    end
  end
end
