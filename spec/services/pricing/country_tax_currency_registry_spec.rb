# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pricing::CountryTaxCurrencyRegistry do
  describe ".for_country" do
    it "returns VAT rate + currency from config for France", :aggregate_failures do
      info = described_class.for_country("fr")
      expect(info[:currency]).to eq("EUR")
      expect(info[:vat_rate]).to eq(BigDecimal("0.2"))
    end

    it "returns GBP for United Kingdom uppercase and lowercase normalization" do
      expect(described_class.for_country("gb")[:currency]).to eq("GBP")
      expect(described_class.for_country("GB")[:vat_rate]).to eq(BigDecimal("0.2"))
    end

    it "returns zero VAT for US numeric zero" do
      expect(described_class.for_country("US")[:vat_rate]).to eq(BigDecimal("0"))
    end

    it "returns nil for unknown ISO code" do
      expect(described_class.for_country("ZZ")).to be_nil
    end

    it "returns nil for blank codes" do
      expect(described_class.for_country(nil)).to be_nil
      expect(described_class.for_country("   ")).to be_nil
    end
  end
end
