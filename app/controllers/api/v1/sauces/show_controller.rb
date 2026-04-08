# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class ShowController < ApplicationController
        include Api::V1::Users::Authentication
        before_action :authenticate_admin!

        def show
          # `with_attached_image` + `find` peut laisser `image.attached?` à false (association vide en cache) ;
          # on précharge explicitement la pièce jointe pour un `image_url` correct.
          sauce = ActiveRecord::Base.uncached do
            Sauce.includes(:category, :stock, :conditionings, :ingredients)
                 .preload(image_attachment: :blob)
                 .find(params[:id])
          end
          render json: { sauce: SauceSerializer.call(sauce, base_url: request.base_url) }, status: :ok
        end
      end
    end
  end
end
