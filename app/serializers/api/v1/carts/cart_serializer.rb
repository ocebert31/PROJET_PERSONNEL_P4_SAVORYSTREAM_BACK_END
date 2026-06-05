# frozen_string_literal: true

module Api
  module V1
    module Carts
      class CartSerializer
        def self.call(cart, base_url: nil, catalog_pricing: nil)
          new(cart, base_url: base_url, catalog_pricing: catalog_pricing).as_json
        end

        def initialize(cart, base_url:, catalog_pricing: nil)
          @cart = cart
          @base_url = base_url
          @catalog_pricing = catalog_pricing
        end

        def as_json
          line_total_bigdecimals = []

          items = @cart.cart_sauces
            .includes(:conditioning, sauce: { image_attachment: :blob })
            .order(created_at: :asc)
            .map do |line|
              unit_bd = Pricing::CatalogAmountConversion.convert_bigdecimal(line.price, @catalog_pricing)
              line_total_bd = (unit_bd * line.quantity).round(2, BigDecimal::ROUND_HALF_UP)
              line_total_bigdecimals << line_total_bd

              {
                id: line.id,
                sauce_id: line.sauce_id,
                sauce_name: line.sauce.name,
                sauce_image_url: Sauces::SauceSerializer.image_url_for(line.sauce, base_url: @base_url),
                conditioning_id: line.conditioning_id,
                volume: line.conditioning.volume,
                quantity: line.quantity,
                unit_price: unit_bd.to_f,
                line_total: line_total_bd.to_f
              }
            end

          total_bd = line_total_bigdecimals
            .inject(BigDecimal("0"), :+)
            .round(2, BigDecimal::ROUND_HALF_UP)

          {
            id: @cart.id,
            user_id: @cart.user_id,
            guest_id: @cart.guest_id,
            items_count: items.sum { |item| item[:quantity] },
            total_amount: total_bd.to_f,
            items: items
          }.merge(pricing_fields)
        end

        private

        def pricing_fields
          return {} if @catalog_pricing.blank?

          {
            display_currency: @catalog_pricing.fetch(:currency_iso),
            prices_base_currency: "EUR"
          }
        end
      end
    end
  end
end
