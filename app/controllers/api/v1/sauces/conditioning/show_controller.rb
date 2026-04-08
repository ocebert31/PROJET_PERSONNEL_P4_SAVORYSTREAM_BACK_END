# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Conditioning
        class ShowController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def show
            conditioning = ::Conditioning.find(params[:id])
            render json: { conditioning: ConditioningSerializer.call(conditioning) }, status: :ok
          end
        end
      end
    end
  end
end
