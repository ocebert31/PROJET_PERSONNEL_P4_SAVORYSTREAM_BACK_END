# frozen_string_literal: true

module Api
  module V1
    module Carts
      module CurrentCartSupport
        extend ActiveSupport::Concern

        include Api::V1::Users::Authentication

        CART_COOKIE_NAME = "guest_cart_id"
        COOKIE_PATH = "/".freeze

        private

        def current_cart
          @current_cart ||= begin
            user = user_from_access_token
            if user
              Cart.find_or_create_by!(user: user, guest_id: nil)
            else
              guest_id = ensure_guest_cart_cookie!
              Cart.find_or_create_by!(user: nil, guest_id: guest_id)
            end
          end
        end

        def ensure_guest_cart_cookie!
          guest_id = cookies[CART_COOKIE_NAME].presence || SecureRandom.uuid
          response.set_cookie(
            CART_COOKIE_NAME,
            value: guest_id,
            path: COOKIE_PATH,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax
          )
          guest_id
        end

        def item_quantity_param(default:)
          raw = params[:quantity]
          return default if raw.nil?

          if raw.is_a?(Float) || raw.is_a?(BigDecimal)
            int = raw.to_i
            raise ActionController::BadRequest, "quantity must be an integer" unless raw == int

            return int
          end

          if raw.is_a?(String)
            raise ActionController::BadRequest, "quantity must be an integer" unless raw.strip.match?(/\A-?\d+\z/)

            return Integer(raw)
          end

          Integer(raw)
        rescue ArgumentError, TypeError
          raise ActionController::BadRequest, "quantity must be an integer"
        end
      end
    end
  end
end
