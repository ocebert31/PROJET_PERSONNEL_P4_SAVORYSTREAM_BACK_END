# frozen_string_literal: true

module LocaleHints
  # Contexte prix catalogue / panier : EUR TTC en base → devise d’affichage pour la requête HTTP courante.
  class CatalogPricingContext
    class << self
      def from(request)
        market = DisplayMarket.resolve(
          accept_language_header: request.get_header("HTTP_ACCEPT_LANGUAGE"),
          default_country_alpha2: Rails.application.config.x.default_market_country_alpha2
        )

        {
          currency_iso: market.catalog_display_currency_iso,
          eur_multiplier: market.catalog_eur_to_display_multiplier
        }
      end
    end
  end
end
