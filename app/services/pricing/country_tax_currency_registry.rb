# frozen_string_literal: true

module Pricing
  # Charge + expose +config/country_vat_currency.yml+ (pays → TVA + devise).
  class CountryTaxCurrencyRegistry
    PATH = Rails.root.join("config/country_vat_currency.yml").freeze

    class << self
      def table
        @table ||= load_table.freeze
      end

      def for_country(alpha2_code)
        return if alpha2_code.blank?

        key = normalize_country(alpha2_code)
        row = table[key]
        return unless row.is_a?(Hash)

        symbolize_keys(row)
      end

      private

      def normalize_country(alpha2_code)
        alpha2_code.to_s.strip.upcase
      end

      def load_table
        raw = YAML.safe_load_file(PATH.to_s, permitted_classes: [], permitted_symbols: [], aliases: false)
        return {} unless raw.is_a?(Hash)

        raw.transform_keys { |k| k.to_s.upcase }.transform_values { |v| v.is_a?(Hash) ? coerce_row(v) : v }
      end

      def coerce_row(hash)
        {
          "vat_rate" => coerce_numeric(hash["vat_rate"]),
          "currency" => normalize_currency(hash["currency"])
        }.compact
      end

      def coerce_numeric(value)
        return if value.nil?
        raise ArgumentError, "vat_rate must be numeric for country row" unless value.is_a?(Numeric)

        BigDecimal(value.to_s)
      end

      def normalize_currency(value)
        code = value.to_s.strip.upcase
        raise ArgumentError, "currency ISO code cannot be blank" if code.blank?

        code
      end

      def symbolize_keys(row)
        {
          vat_rate: row.fetch("vat_rate"),
          currency: row.fetch("currency")
        }
      end
    end
  end
end
