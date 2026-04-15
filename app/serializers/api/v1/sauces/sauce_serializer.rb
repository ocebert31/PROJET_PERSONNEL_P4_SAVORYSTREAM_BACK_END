# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class SauceSerializer
        include Rails.application.routes.url_helpers

        def self.call(sauce, base_url:)
          new(sauce, base_url: base_url).as_json
        end

        def initialize(sauce, base_url:)
          @sauce = sauce
          @base_url = base_url
        end

        def as_json
          {
            id: @sauce.id,
            name: @sauce.name,
            tagline: @sauce.tagline,
            description: @sauce.description,
            characteristic: @sauce.characteristic,
            image_url: image_url,
            is_available: @sauce.is_available,
            category: @sauce.category && { id: @sauce.category.id, name: @sauce.category.name },
            stock: @sauce.stock && { id: @sauce.stock.id, quantity: @sauce.stock.quantity },
            conditionings: @sauce.conditionings.order(:created_at).map do |c|
              { id: c.id, volume: c.volume, price: c.price.to_s }
            end,
            ingredients: @sauce.ingredients.order(:created_at).map do |i|
              { id: i.id, name: i.name, quantity: i.quantity }
            end,
            created_at: @sauce.created_at,
            updated_at: @sauce.updated_at
          }
        end

        private

        def image_url
          return nil unless @sauce.image.attached?

          blob = @sauce.image.blob
          path = rails_blob_path(blob, only_path: true)
          return "#{@base_url}#{path}" if path.present?

          nil
        end
      end
    end
  end
end
