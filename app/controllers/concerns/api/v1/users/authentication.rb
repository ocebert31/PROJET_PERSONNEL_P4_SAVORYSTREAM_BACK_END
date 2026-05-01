# frozen_string_literal: true

module Api
  module V1
    module Users
      module Authentication
        extend ActiveSupport::Concern

        private

        def current_user
          @current_user
        end

        def authenticate_admin!
          authenticate_user!
          return if performed?
          return if current_user&.admin?

          render json: { message: "Accès réservé aux administrateurs." }, status: :forbidden
        end

        def authenticate_user!
          @current_user = user_from_access_token
          return if @current_user.present?

          render json: { message: "Token d'accès invalide ou manquant." }, status: :unauthorized
        end

        # User from access JWT (Bearer or cookie) without rendering — for optional-auth flows (e.g. cart).
        def user_from_access_token
          token = raw_access_token
          return nil if token.blank?

          payload = JwtAccessToken.decode(token)
          return nil unless payload&.dig("typ") == "access"

          User.find_by(id: payload["sub"])
        end

        def bearer_token
          auth_header = request.headers["Authorization"].to_s
          auth_header.start_with?("Bearer ") ? auth_header.delete_prefix("Bearer ").strip : nil
        end

        def raw_access_token
          bearer_token.presence || cookies[JwtConfig::ACCESS_COOKIE_NAME].presence
        end
      end
    end
  end
end
