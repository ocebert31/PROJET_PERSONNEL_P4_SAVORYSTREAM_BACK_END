# frozen_string_literal: true

module Api
  module V1
    module Users
      class SessionsController < ApplicationController
        # Connexion : valide email ou téléphone + mot de passe, puis émet un JWT d'accès et un refresh token
        # persisté (table users_authentification). Réponse inclut l'utilisateur et les durées d'expiration.
        def create
          identification = SessionIdentification.new(session_params)
          if identification.invalid?
            return render json: { errors: identification.errors_hash }, status: :unprocessable_entity
          end

          user = find_user(identification)
          unless user&.authenticate(session_params[:password])
            return render json: { message: "Impossible de vous connecter. Vérifiez vos informations." }, status: :unauthorized
          end

          # « Se souvenir de moi » : accepte remember_me ou rememberMe (camelCase), défaut false si absent (évite nil).
          # ActiveModel::Type::Boolean normalise les chaînes ("true", "1", etc.) en vrai booléen.
          remember = ActiveModel::Type::Boolean.new.cast(
            session_params[:remember_me] || session_params[:rememberMe] || false
          )
          # Enregistre le refresh en base (empreinte seulement) et retourne le jeton brut pour le client + l'enregistrement.
          raw_refresh, refresh_record = UsersAuthentification.create_for_user!(user, remember_me: remember)
          # JWT d'accès court (durée dans JwtConfig), distinct du refresh.
          access = JwtAccessToken.encode(user.id)

          response.set_cookie(
            JwtConfig::REFRESH_COOKIE_NAME,
            value: raw_refresh,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax,
            expires: refresh_record.expires_at
          )

          render json: {
            message: "Connexion réussie.",
            access_token: access,
            access_expires_in: JwtConfig.access_token_ttl.to_i,
            refresh_expires_at: refresh_record.expires_at.iso8601,
            remember_me: refresh_record.remember_me,
            user: UserSerializer.call(user)
          }, status: :ok
        end

        # Émet un nouvel access token à partir d'un refresh token encore valide (non expiré, non révoqué).
        # Le refresh token lui-même n'est pas régénéré ici.
        def refresh
          raw = cookies[JwtConfig::REFRESH_COOKIE_NAME].presence
          record = UsersAuthentification.find_valid(raw)
          unless record
            return render json: { message: "Refresh token invalide ou expiré." }, status: :unauthorized
          end

          user = record.user
          access = JwtAccessToken.encode(user.id)

          render json: {
            access_token: access,
            access_expires_in: JwtConfig.access_token_ttl.to_i,
            refresh_expires_at: record.expires_at.iso8601
          }, status: :ok
        end

        # Déconnexion côté API : marque le refresh token comme révoqué (revoked_at) pour qu'il ne soit plus accepté.
        def revoke
          raw = cookies[JwtConfig::REFRESH_COOKIE_NAME].presence
          record = UsersAuthentification.find_valid(raw)
          unless record
            return render json: { message: "Refresh token invalide ou expiré." }, status: :unauthorized
          end

          record.revoke!
          response.delete_cookie(JwtConfig::REFRESH_COOKIE_NAME, httponly: true, secure: Rails.env.production?, same_site: :lax)
          head :no_content
        end

        private

        def session_params
          params.permit(:email, :phone_number, :phoneNumber, :password, :remember_me, :rememberMe)
        end

        def find_user(identification)
          if identification.email.present?
            User.find_by(email: identification.email)
          else
            User.find_by(phone_number: identification.phone)
          end
        end
      end
    end
  end
end
