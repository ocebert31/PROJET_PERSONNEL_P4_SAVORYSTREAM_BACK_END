# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class ConditioningParameters
        def initialize(raw_params)
          @raw_params = raw_params
        end

        def permitted
          @raw_params.permit(:volume, :price, :sauce_id)
        end
      end
    end
  end
end
