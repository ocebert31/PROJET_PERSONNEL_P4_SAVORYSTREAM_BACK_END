# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class IngredientParameters
        def initialize(raw_params)
          @raw_params = raw_params
        end

        def permitted
          @raw_params.permit(:name, :quantity, :sauce_id)
        end
      end
    end
  end
end
