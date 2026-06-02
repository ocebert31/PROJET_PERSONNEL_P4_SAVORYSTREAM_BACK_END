# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocaleHints::CatalogPricingContext do
  describe ".from" do
    def http_request(accept_language)
      instance_double(ActionDispatch::Request).tap do |req|
        allow(req).to receive(:get_header).with("HTTP_ACCEPT_LANGUAGE").and_return(accept_language)
      end
    end

    def context_from(accept_language, default_country: "FR")
      allow(Rails.application.config.x).to receive_messages(default_market_country_alpha2: default_country)
      described_class.from(http_request(accept_language))
    end

    it "reads Accept-Language via HTTP_ACCEPT_LANGUAGE on the request" do
      request = http_request("en-GB;q=1")
      allow(Rails.application.config.x).to receive_messages(default_market_country_alpha2: "FR")

      expect(LocaleHints::DisplayMarket).to receive(:resolve).with(
        accept_language_header: "en-GB;q=1",
        default_country_alpha2: "FR"
      ).and_call_original

      described_class.from(request)
    end

    it "returns only currency_iso and eur_multiplier keys" do
      result = context_from("en-US")

      expect(result.keys).to contain_exactly(:currency_iso, :eur_multiplier)
    end

    context "when default market is FR and Accept-Language is absent" do
      it "returns EUR identity context" do
        expect(context_from(nil)).to eq(
          currency_iso: "EUR",
          eur_multiplier: BigDecimal("1")
        )
      end

      it "treats blank Accept-Language like absent" do
        expect(context_from("")).to eq(
          currency_iso: "EUR",
          eur_multiplier: BigDecimal("1")
        )
      end
    end

    context "when default market is DE and Accept-Language is absent" do
      it "returns EUR context from the configured default country" do
        expect(context_from(nil, default_country: "DE")).to eq(
          currency_iso: "EUR",
          eur_multiplier: BigDecimal("1")
        )
      end
    end

    context "when Accept-Language carries a regional market" do
      it "returns USD context for en-US" do
        expect(context_from("en-US,fr;q=0.6")).to eq(
          currency_iso: "USD",
          eur_multiplier: BigDecimal("1.08")
        )
      end

      it "returns CHF context for fr-CH" do
        expect(context_from("fr-CH,fr;q=0.9")).to eq(
          currency_iso: "CHF",
          eur_multiplier: BigDecimal("0.95")
        )
      end

      it "returns GBP context for en-GB despite default FR" do
        expect(context_from("en-GB;q=1")).to eq(
          currency_iso: "GBP",
          eur_multiplier: BigDecimal("0.87")
        )
      end

      it "returns CAD context for en-CA" do
        expect(context_from("en-CA;q=1")).to eq(
          currency_iso: "CAD",
          eur_multiplier: BigDecimal("1.48")
        )
      end
    end

    context "when region cannot be resolved from Accept-Language" do
      it "falls back to default country currency (FR → EUR)" do
        expect(context_from("en-XX;q=1")).to eq(
          currency_iso: "EUR",
          eur_multiplier: BigDecimal("1")
        )
      end

      it "falls back to FR when default country code is unknown in YAML" do
        expect(context_from(nil, default_country: "XX")).to eq(
          currency_iso: "EUR",
          eur_multiplier: BigDecimal("1")
        )
      end
    end

    context "when used by serializers via CatalogAmountConversion" do
      it "converts a nominal EUR TTC amount with the returned multiplier" do
        pricing = context_from("en-US,fr;q=0.6")

        converted = Pricing::CatalogAmountConversion.convert_to_string(10, pricing)

        expect(converted).to eq(BigDecimal("10.8").to_s("F"))
      end
    end
  end
end
