# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class CategoryParameters
        def initialize(raw_params)
          @raw_params = raw_params
        end

        def permitted
          @raw_params.permit(:name)
        end
      end
    end
  end
end
