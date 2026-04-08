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
          payload = JwtAccessToken.decode(bearer_token)
          unless payload&.dig("typ") == "access"
            return render json: { message: "Token d'accès invalide ou manquant." }, status: :unauthorized
          end

          @current_user = User.find_by(id: payload["sub"])
          return if @current_user.present?

          render json: { message: "Token d'accès invalide ou manquant." }, status: :unauthorized
        end

        def bearer_token
          auth_header = request.headers["Authorization"].to_s
          auth_header.start_with?("Bearer ") ? auth_header.delete_prefix("Bearer ").strip : nil
        end
      end
    end
  end
end
