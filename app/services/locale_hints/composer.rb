# frozen_string_literal: true

module LocaleHints
  # Assemble le payload JSON marché pays / devise / TVA depuis la config YAML et les registres pricing.
  class Composer
    class << self
      # @param accept_language_header [String, nil]
      # @param default_country_alpha2 [String]
      # @return [Hash] clé racine `:localisations` pour `render json:`
      def call(accept_language_header:, default_country_alpha2:)
        market = LocaleHints::DisplayMarket.resolve(
          accept_language_header: accept_language_header,
          default_country_alpha2: default_country_alpha2
        )

        { localisations: market.as_localisations_hash }
      end
    end
  end
end
