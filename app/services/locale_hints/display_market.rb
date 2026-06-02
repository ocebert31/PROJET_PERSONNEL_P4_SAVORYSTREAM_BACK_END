# frozen_string_literal: true

module LocaleHints
  # From the Accept-Language header and the server default country, infers which market the client
  # represents (country, currency, indicative VAT) and how to display catalogue prices stored as
  # EUR TTC amounts.
  #
  # Language is resolved first by +AcceptLanguageNegotiator+. The country is taken from the
  # +locale_tag+ region (e.g. +en-US+ → United States) only when that language truly comes from the
  # header; otherwise we fall back to +default_market_country_alpha2+, without conflating this with
  # the linguistic default +fr-FR+ applied when Accept-Language is absent.
  #
  # Country data comes from +country_vat_currency.yml+; the display multiplier from
  # +eur_exchange_rates.yml+. VAT is mainly for the +/api/v1/localisations+ endpoint; catalogue and
  # cart amount conversion goes through +CatalogPricingContext+ and the serializers. Unknown
  # countries or rates fall back to France and the euro with no multiplication.
  class DisplayMarket
    ResolveResult = Struct.new(
      :negotiation,
      :resolved_country_alpha2,
      :country_source_for_hints,
      :tax_row,
      :catalog_display_currency_iso,
      :catalog_eur_to_display_multiplier,
      keyword_init: true
    ) do
      def as_localisations_hash
        h = {
          language: negotiation.language,
          locale_tag: negotiation.locale_tag,
          country_alpha2: resolved_country_alpha2,
          currency: tax_row.fetch(:currency),
          vat_rate: tax_row.fetch(:vat_rate).to_s("F"),
          sources: {
            country: country_source_for_hints,
            language: negotiation.language_source
          }
        }
        LocaleHints::DisplayMarket.attach_eur_conversion_rate!(h, tax_row.fetch(:currency))
        h
      end
    end

    class << self
      def resolve(accept_language_header:, default_country_alpha2:)
        negotiation = AcceptLanguageNegotiator.call(accept_language_header)
        default_country = normalize_country_alpha2(default_country_alpha2)
        inferred = infer_country_alpha2_from_locale_tag(negotiation)
        country_choice, country_source = resolve_country_choice(
          negotiation: negotiation,
          inferred_from_tag: inferred,
          default_country: default_country
        )
        row, resolved_country = tax_row_for_country(country_choice)
        catalog = projection_for_catalog_pricing(row)

        ResolveResult.new(
          negotiation: negotiation,
          resolved_country_alpha2: resolved_country,
          country_source_for_hints: country_source,
          tax_row: row,
          catalog_display_currency_iso: catalog.fetch(:currency_iso),
          catalog_eur_to_display_multiplier: catalog.fetch(:eur_multiplier)
        )
      end

      def attach_eur_conversion_rate!(hint, currency_iso)
        return if currency_iso == "EUR"
        return unless Pricing::EurExchangeRateRegistry.multiplier_from_eur?(currency_iso)

        hint[:eur_to_currency_rate] = Pricing::EurExchangeRateRegistry.multiplier_from_eur(currency_iso).to_s("F")
      end

      private

      def resolve_country_choice(negotiation:, inferred_from_tag:, default_country:)
        if negotiation.from_header? && inferred_from_tag
          return [ inferred_from_tag, "accept_language_region" ]
        end

        [ default_country, "default_config" ]
      end

      def infer_country_alpha2_from_locale_tag(negotiation)
        tag = negotiation.locale_tag.to_s.strip
        return nil if tag.blank?

        tag.split("-").drop(1).each do |segment|
          next unless segment.match?(/\A[A-Z]{2}\z/)

          return segment if Pricing::CountryTaxCurrencyRegistry.for_country(segment)
        end

        nil
      end

      def normalize_country_alpha2(code)
        c = code.to_s.strip.upcase
        return c if c.match?(/\A[A-Z]{2}\z/)

        "FR"
      end

      def tax_row_for_country(normalized_country)
        row = Pricing::CountryTaxCurrencyRegistry.for_country(normalized_country)
        return [ row, normalized_country ] if row

        row_fr = Pricing::CountryTaxCurrencyRegistry.for_country("FR")
        raise KeyError, "country FR manquant dans config/country_vat_currency.yml" unless row_fr

        [ row_fr, "FR" ]
      end

      # Prix catalogue : euros TTC en base → valeur affichée ; sans taux on reste en EUR.
      def projection_for_catalog_pricing(tax_row)
        currency = tax_row.fetch(:currency).to_s.upcase

        return { currency_iso: "EUR", eur_multiplier: BigDecimal("1") } if currency == "EUR"
        return { currency_iso: currency, eur_multiplier: Pricing::EurExchangeRateRegistry.multiplier_from_eur(currency) } \
          if Pricing::EurExchangeRateRegistry.multiplier_from_eur?(currency)

        { currency_iso: "EUR", eur_multiplier: BigDecimal("1") }
      end
    end
  end
end
