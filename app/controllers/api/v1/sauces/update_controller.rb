# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class UpdateController < ApplicationController
        include Api::V1::Users::Authentication
        before_action :authenticate_admin!

        def update
          req = SauceParameters.new(params)
          image_file = req.image_upload
          sauce = Sauce.find(params[:id])

          if sauce.update(SauceAttributesMapper.call(req.permitted))
            sauce.image.attach(image_file) if image_file
            reloaded = SauceReloader.with_includes!(sauce)
            render json: { message: "Sauce mise à jour.", sauce: SauceSerializer.call(reloaded, base_url: request.base_url) }, status: :ok
          else
            render json: { errors: sauce.errors.messages }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
