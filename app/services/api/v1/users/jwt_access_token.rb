# frozen_string_literal: true

require "jwt"

module Api
  module V1
    module Users
      # JWT court (accès API) signé HS256 — payload minimal : sub = user id.
      module JwtAccessToken
        module_function

        def encode(user_id)
          now = Time.current
          payload = {
            sub: user_id,
            exp: (now + JwtConfig.access_token_ttl).to_i,
            iat: now.to_i,
            typ: "access",
            jti: SecureRandom.uuid
          }
          JWT.encode(payload, JwtConfig.secret, "HS256")
        end

        def decode(token)
          decoded = JWT.decode(token, JwtConfig.secret, true, { algorithm: "HS256" })
          decoded.first
        rescue JWT::DecodeError, JWT::ExpiredSignature
          nil
        end
      end
    end
  end
end
