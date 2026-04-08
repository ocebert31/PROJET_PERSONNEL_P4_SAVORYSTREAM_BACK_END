# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Conditioning
        class UpdateController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def update
            conditioning = ::Conditioning.find(params[:id])
            if conditioning.update(ConditioningParameters.new(params).permitted)
              render json: { message: "Conditionnement mis à jour.", conditioning: ConditioningSerializer.call(conditioning) }, status: :ok
            else
              render json: { errors: conditioning.errors.messages }, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end
