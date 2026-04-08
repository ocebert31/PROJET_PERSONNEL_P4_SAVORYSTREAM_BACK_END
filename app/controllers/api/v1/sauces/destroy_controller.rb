# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class DestroyController < ApplicationController
        include Api::V1::Users::Authentication
        before_action :authenticate_admin!

        def destroy
          sauce = Sauce.find(params[:id])
          sauce.destroy!
          head :no_content
        end
      end
    end
  end
end
