# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocaleHints::DisplayMarket do
  def market_resolve(accept_language, default_country: "FR")
    LocaleHints::DisplayMarket.resolve(
      accept_language_header: accept_language,
      default_country_alpha2: default_country
    )
  end

  describe ".resolve" do
    context "nominal case — default French market" do
      it "resolves France in EUR with no conversion when Accept-Language is absent" do
        result = market_resolve(nil, default_country: "FR")

        expect(result.resolved_country_alpha2).to eq("FR")
        expect(result.country_source_for_hints).to eq("default_config")
        expect(result.negotiation.language).to eq("fr")
        expect(result.negotiation.locale_tag).to eq("fr-FR")
        expect(result.negotiation).not_to be_from_header
        expect(result.tax_row.fetch(:currency)).to eq("EUR")
        expect(result.tax_row.fetch(:vat_rate)).to eq(BigDecimal("0.2"))
        expect(result.catalog_display_currency_iso).to eq("EUR")
        expect(result.catalog_eur_to_display_multiplier).to eq(BigDecimal("1"))
      end
    end

    context "nominal case — market inferred from Accept-Language" do
      it "resolves the United States in USD with multiplier from en-US" do
        result = market_resolve("en-US,fr;q=0.6")

        expect(result.resolved_country_alpha2).to eq("US")
        expect(result.country_source_for_hints).to eq("accept_language_region")
        expect(result.negotiation).to be_from_header
        expect(result.negotiation.language).to eq("en")
        expect(result.negotiation.locale_tag).to eq("en-US")
        expect(result.tax_row.fetch(:currency)).to eq("USD")
        expect(result.tax_row.fetch(:vat_rate)).to eq(BigDecimal("0"))
        expect(result.catalog_display_currency_iso).to eq("USD")
        expect(result.catalog_eur_to_display_multiplier).to eq(BigDecimal("1.08"))
      end
    end

    context "other known regional markets" do
      it "resolves Switzerland from fr-CH" do
        result = market_resolve("fr-CH,fr;q=0.9")

        expect(result.resolved_country_alpha2).to eq("CH")
        expect(result.country_source_for_hints).to eq("accept_language_region")
        expect(result.tax_row.fetch(:currency)).to eq("CHF")
        expect(result.tax_row.fetch(:vat_rate)).to eq(BigDecimal("0.081"))
        expect(result.catalog_eur_to_display_multiplier).to eq(BigDecimal("0.95"))
      end

      it "resolves Great Britain from en-GB despite FR server default" do
        result = market_resolve("en-GB;q=1", default_country: "FR")

        expect(result.resolved_country_alpha2).to eq("GB")
        expect(result.tax_row.fetch(:currency)).to eq("GBP")
        expect(result.catalog_eur_to_display_multiplier).to eq(BigDecimal("0.87"))
      end

      it "resolves Canada from en-CA" do
        result = market_resolve("en-CA;q=1")

        expect(result.resolved_country_alpha2).to eq("CA")
        expect(result.tax_row.fetch(:currency)).to eq("CAD")
        expect(result.catalog_eur_to_display_multiplier).to eq(BigDecimal("1.48"))
      end
    end

    context "fallback and edge cases" do
      it "uses configured server country without inferring country from synthetic fr-FR" do
        result = market_resolve(nil, default_country: "DE")

        expect(result.resolved_country_alpha2).to eq("DE")
        expect(result.country_source_for_hints).to eq("default_config")
        expect(result.negotiation.locale_tag).to eq("fr-FR")
        expect(result.catalog_display_currency_iso).to eq("EUR")
        expect(result.catalog_eur_to_display_multiplier).to eq(BigDecimal("1"))
      end

      it "falls back to FR when server default country is unknown in YAML" do
        result = market_resolve(nil, default_country: "XX")

        expect(result.resolved_country_alpha2).to eq("FR")
        expect(result.country_source_for_hints).to eq("default_config")
        expect(result.tax_row.fetch(:currency)).to eq("EUR")
      end

      it "keeps server default when header carries language only without region" do
        result = market_resolve("fr,en;q=0.5", default_country: "FR")

        expect(result.negotiation.locale_tag).to eq("fr")
        expect(result.negotiation).to be_from_header
        expect(result.resolved_country_alpha2).to eq("FR")
        expect(result.country_source_for_hints).to eq("default_config")
      end

      it "keeps server default when tag region is missing from YAML" do
        result = market_resolve("en-XX;q=1", default_country: "FR")

        expect(result.resolved_country_alpha2).to eq("FR")
        expect(result.country_source_for_hints).to eq("default_config")
      end
    end
  end

  describe LocaleHints::DisplayMarket::ResolveResult do
    describe "#as_localisations_hash" do
      context "nominal case — euro market" do
        it "builds FR localisations payload without eur_to_currency_rate" do
          result = market_resolve(nil, default_country: "FR")
          hints = result.as_localisations_hash

          expect(hints[:language]).to eq("fr")
          expect(hints[:locale_tag]).to eq("fr-FR")
          expect(hints[:country_alpha2]).to eq("FR")
          expect(hints[:currency]).to eq("EUR")
          expect(hints[:vat_rate]).to eq("0.2")
          expect(hints[:sources]).to eq(
            country: "default_config",
            language: LocaleHints::AcceptLanguageNegotiator::SOURCE_DEFAULT
          )
          expect(hints).not_to have_key(:eur_to_currency_rate)
        end
      end

      context "nominal case — converted market" do
        it "adds eur_to_currency_rate for a USD market" do
          result = market_resolve("en-US")
          hints = result.as_localisations_hash

          expect(hints[:language]).to eq("en")
          expect(hints[:locale_tag]).to eq("en-US")
          expect(hints[:country_alpha2]).to eq("US")
          expect(hints[:currency]).to eq("USD")
          expect(hints[:vat_rate]).to eq(BigDecimal("0").to_s("F"))
          expect(hints[:eur_to_currency_rate]).to eq(BigDecimal("1.08").to_s("F"))
          expect(hints[:sources]).to eq(
            country: "accept_language_region",
            language: LocaleHints::AcceptLanguageNegotiator::SOURCE_ACCEPT_LANGUAGE
          )
        end
      end
    end
  end

  describe ".attach_eur_conversion_rate!" do
    context "nominal case" do
      it "adds configured multiplier for a non-EUR currency" do
        hint = { currency: "USD" }

        described_class.attach_eur_conversion_rate!(hint, "USD")

        expect(hint[:eur_to_currency_rate]).to eq(BigDecimal("1.08").to_s("F"))
      end
    end

    context "edge cases" do
      it "does not add a rate when currency is already EUR" do
        hint = { currency: "EUR" }

        described_class.attach_eur_conversion_rate!(hint, "EUR")

        expect(hint).not_to have_key(:eur_to_currency_rate)
      end

      it "leaves hash unchanged when no EUR rate is configured for the currency" do
        hint = { currency: "ZZZ" }

        described_class.attach_eur_conversion_rate!(hint, "ZZZ")

        expect(hint).not_to have_key(:eur_to_currency_rate)
      end
    end
  end
end
