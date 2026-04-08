# frozen_string_literal: true

# Helpers partagés pour les request specs API JSON + JWT Bearer.
# Les données (users admin/customer, category, sauce…) restent dans les
# `*_request_setup.rb` par domaine.
module ApiV1RequestHelpers
  def json_headers
    { "Content-Type" => "application/json" }
  end

  def auth_headers_for(user)
    token = Api::V1::Users::JwtAccessToken.encode(user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  def response_json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include ApiV1RequestHelpers, type: :request
end
