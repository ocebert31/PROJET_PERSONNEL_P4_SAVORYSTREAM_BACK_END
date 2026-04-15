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
            :name, :tagline, :description, :characteristic, :is_available, :category_id,
            :isAvailable, :categoryId, :image,
            stock: [ :quantity ],
            conditionings: [ :volume, :price ],
            ingredients: [ :name, :quantity ]
          )
        end

        def image_upload
          permitted[:image]
        end

        # Règles "create" API : tous les champs métier du formulaire admin sont obligatoires.
        def create_required_errors
          Api::V1::Sauces::SauceCreateRequiredValidator
            .new(permitted: permitted, image_upload: image_upload)
            .errors
        end

        private
      end
    end
  end
end
