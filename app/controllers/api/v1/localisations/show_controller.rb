# frozen_string_literal: true

module Api
  module V1
    module Localisations
      class ShowController < ApplicationController
        def show
          payload = ::LocaleHints::Composer.call(
            accept_language_header: request.get_header("HTTP_ACCEPT_LANGUAGE"),
            default_country_alpha2: Rails.application.config.x.default_market_country_alpha2
          )

          render json: payload, status: :ok
        end
      end
    end
  end
end
