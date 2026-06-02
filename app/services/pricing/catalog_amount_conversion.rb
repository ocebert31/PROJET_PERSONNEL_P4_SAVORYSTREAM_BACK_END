# frozen_string_literal: true

module Pricing
  # EUR TTC amounts × +catalog_pricing[:eur_multiplier]+ for display; unchanged when pricing is blank.
  # Used by catalogue and cart serializers. Not VAT or market resolution.
  class CatalogAmountConversion
    class << self
      def convert_bigdecimal(amount_eur_ttc, catalog_pricing)
        amt = BigDecimal(amount_eur_ttc.to_s)
        return amt if catalog_pricing.blank?

        mult = BigDecimal(catalog_pricing.fetch(:eur_multiplier).to_s)
        raise ArgumentError, "eur_multiplier must be positive" unless mult.positive?

        (amt * mult).round(2, BigDecimal::ROUND_HALF_UP)
      end

      def convert_to_float(amount_eur_ttc, catalog_pricing)
        convert_bigdecimal(amount_eur_ttc, catalog_pricing).to_f
      end

      def convert_to_string(amount_eur_ttc, catalog_pricing)
        convert_bigdecimal(amount_eur_ttc, catalog_pricing).to_s("F")
      end
    end
  end
end
