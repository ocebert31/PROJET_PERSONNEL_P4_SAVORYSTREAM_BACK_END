# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Conditioning
        class CreateController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def create
            conditioning = ::Conditioning.new(ConditioningParameters.new(params).permitted)
            if conditioning.save
              render json: { message: "Conditionnement créé.", conditioning: ConditioningSerializer.call(conditioning) }, status: :created
            else
              render json: { errors: conditioning.errors.messages }, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end
