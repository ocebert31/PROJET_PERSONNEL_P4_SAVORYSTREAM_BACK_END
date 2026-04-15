# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class CreateController < ApplicationController
        include Api::V1::Users::Authentication
        before_action :authenticate_admin!

        def create
          req = SauceParameters.new(params)
          required_errors = req.create_required_errors
          if required_errors.present?
            return render json: { errors: required_errors }, status: :unprocessable_entity
          end

          image_file = req.image_upload
          sauce = Sauce.new(SauceAttributesMapper.call(req.permitted))

          if sauce.save
            sauce.image.attach(image_file) if image_file
            reloaded = SauceReloader.with_includes!(sauce)
            render json: { message: "Sauce créée.", sauce: SauceSerializer.call(reloaded, base_url: request.base_url) }, status: :created
          else
            render json: { errors: sauce.errors.messages }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
