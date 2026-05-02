# frozen_string_literal: true

module Api
  module V1
    module Carts
      class CartSerializer
        def self.call(cart, base_url: nil)
          items = cart.cart_sauces
            .includes(:conditioning, sauce: { image_attachment: :blob })
            .order(created_at: :asc)
            .map do |line|
              {
                id: line.id,
                sauce_id: line.sauce_id,
                sauce_name: line.sauce.name,
                sauce_image_url: Sauces::SauceSerializer.image_url_for(line.sauce, base_url: base_url),
                conditioning_id: line.conditioning_id,
                volume: line.conditioning.volume,
                quantity: line.quantity,
                unit_price: line.price.to_f,
                line_total: (line.quantity * line.price).to_f
              }
            end

          {
            id: cart.id,
            user_id: cart.user_id,
            guest_id: cart.guest_id,
            items_count: items.sum { |item| item[:quantity] },
            total_amount: items.sum { |item| item[:line_total] }.round(2),
            items: items
          }
        end
      end
    end
  end
end
