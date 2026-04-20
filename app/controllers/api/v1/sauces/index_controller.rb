# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class IndexController < ApplicationController
        def index
          # Hors cache : évite un jeu de lignes `active_storage_*` réutilisé à vide entre requêtes.
          # `preload(image_attachment: :blob)` remplace `with_attached_image`, qui peut casser
          # `image.attached?` après chargement et laisser `image_url` à nil.
          sauces = ActiveRecord::Base.uncached do
            Sauce.includes(:category, :stock, :conditionings, :ingredients)
                 .preload(image_attachment: :blob)
                 .order(:name)
                 .to_a
          end
          render json: { sauces: sauces.map { |s| SauceSerializer.call(s, base_url: request.base_url) } }, status: :ok
        end
      end
    end
  end
end
