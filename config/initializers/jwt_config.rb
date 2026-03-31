# frozen_string_literal: true

module JwtConfig
  REFRESH_COOKIE_NAME = "ss_refresh".freeze

  class << self
    def secret
      @secret ||= ENV.fetch("JWT_SECRET_KEY") { Rails.application.secret_key_base }
    end

    def access_token_ttl
      15.minutes
    end

    def refresh_token_ttl_for(remember_me)
      remember_me ? 30.days : 7.days
    end
  end
end
