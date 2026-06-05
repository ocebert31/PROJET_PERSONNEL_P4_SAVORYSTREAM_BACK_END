# frozen_string_literal: true

module Pricing
  # Charge + expose +config/eur_exchange_rates.yml+ (devise cible ← multiplicateur depuis l’EUR).
  class EurExchangeRateRegistry
    PATH = Rails.root.join("config/eur_exchange_rates.yml").freeze

    class << self
      def rates
        @rates ||= load_rates.freeze
      end

      # @return [BigDecimal] multiplier such that amount_in_currency = amount_eur * multiplier
      def multiplier_from_eur(currency_iso4217)
        key = normalize_currency(currency_iso4217)
        rates.fetch(key) do
          raise KeyError,
                "Pas de taux EUR → #{key} défini dans config/eur_exchange_rates.yml."
        end
      end

      def multiplier_from_eur?(currency_iso4217)
        key = normalize_currency(currency_iso4217)
        rates.key?(key)
      end

      private

      def normalize_currency(value)
        code = value.to_s.strip.upcase
        raise ArgumentError, "code devise ISO invalide ou vide." if code.blank?

        code
      end

      def load_rates
        raw = YAML.safe_load_file(PATH.to_s, permitted_classes: [], permitted_symbols: [], aliases: false)
        return {} unless raw.is_a?(Hash)

        raw.transform_keys { |currency_code| normalize_currency(currency_code) }
          .transform_values { |v| coerce_rate(v) }
      end

      def coerce_rate(value)
        raise ArgumentError, "Les taux de change doivent être numériques." unless value.is_a?(Numeric)

        BigDecimal(value.to_s)
      end
    end
  end
end
