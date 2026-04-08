# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class IngredientSerializer
        def self.call(ingredient)
          new(ingredient).as_json
        end

        def initialize(ingredient)
          @ingredient = ingredient
        end

        def as_json
          {
            id: @ingredient.id,
            name: @ingredient.name,
            quantity: @ingredient.quantity,
            sauce_id: @ingredient.sauce_id,
            created_at: @ingredient.created_at,
            updated_at: @ingredient.updated_at
          }
        end
      end
    end
  end
end
