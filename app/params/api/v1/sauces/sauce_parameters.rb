# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class SauceParameters
        def initialize(raw_params)
          @raw_params = raw_params
        end

        def permitted
          @permitted ||= @raw_params.permit(
            :name, :tagline, :description, :characteristic, :image_url, :is_available, :category_id,
            :imageUrl, :isAvailable, :categoryId, :image,
            stock: [ :quantity ],
            conditionings: [ :volume, :price ],
            ingredients: [ :name, :quantity ]
          )
        end

        def image_upload
          permitted[:image]
        end
      end
    end
  end
end
