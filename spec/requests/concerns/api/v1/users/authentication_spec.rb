# frozen_string_literal: true

require "rails_helper"
require "jwt"

RSpec.describe Api::V1::Users::Authentication, type: :controller do
  controller(ApplicationController) do
    include Api::V1::Users::Authentication

    def current_user_probe
      authenticate_user!
      return if performed?

      render json: { id: current_user.id, same_instance: current_user.equal?(@current_user) }, status: :ok
    end

    def authenticate_admin_probe
      authenticate_admin!
      render json: { id: current_user&.id }, status: :ok unless performed?
    end

    def authenticate_user_probe
      authenticate_user!
      render json: { id: current_user&.id, role: current_user&.role }, status: :ok unless performed?
    end

    def bearer_token_probe
      render json: { token: bearer_token }
    end

    def raw_access_token_probe
      render json: { raw: raw_access_token }, status: :ok
    end
  end

  before do
    routes.draw do
      get :current_user_probe, to: "anonymous#current_user_probe"
      get :authenticate_admin_probe, to: "anonymous#authenticate_admin_probe"
      get :authenticate_user_probe, to: "anonymous#authenticate_user_probe"
      get :bearer_token_probe, to: "anonymous#bearer_token_probe"
      get :raw_access_token_probe, to: "anonymous#raw_access_token_probe"
    end
  end

  def json_response
    response.parsed_body
  end

  describe "#current_user" do
    let!(:admin) { create(:user, :admin) }

    it "returns the user loaded by authenticate_user!" do
      token = Api::V1::Users::JwtAccessToken.encode(admin.id)
      request.headers["Authorization"] = "Bearer #{token}"

      get :current_user_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(admin.id)
      expect(json_response["same_instance"]).to be true
    end
  end

  describe "#authenticate_admin!" do
    let!(:admin) { create(:user, :admin) }
    let!(:customer) { create(:user) }

    it "allows the request when the user is an admin" do
      token = Api::V1::Users::JwtAccessToken.encode(admin.id)
      request.headers["Authorization"] = "Bearer #{token}"

      get :authenticate_admin_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(admin.id)
    end

    it "renders forbidden when the user is not an admin" do
      token = Api::V1::Users::JwtAccessToken.encode(customer.id)
      request.headers["Authorization"] = "Bearer #{token}"

      get :authenticate_admin_probe

      expect(response).to have_http_status(:forbidden)
      expect(json_response["message"]).to eq("Accès réservé aux administrateurs.")
    end

    it "does not render forbidden when authenticate_user! already responded" do
      get :authenticate_admin_probe

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["message"]).to eq("Token d'accès invalide ou manquant.")
    end
  end

  describe "#authenticate_user!" do
    let!(:admin) { create(:user, :admin) }

    it "allows the request and exposes the user when the access token is valid" do
      token = Api::V1::Users::JwtAccessToken.encode(admin.id)
      request.headers["Authorization"] = "Bearer #{token}"

      get :authenticate_user_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(admin.id)
      expect(json_response["role"]).to eq("admin")
    end

    it "renders unauthorized when bearer_token is nil" do
      get :authenticate_user_probe

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["message"]).to eq("Token d'accès invalide ou manquant.")
    end

    it "renders unauthorized when the JWT is invalid" do
      request.headers["Authorization"] = "Bearer not-a-jwt"

      get :authenticate_user_probe

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["message"]).to eq("Token d'accès invalide ou manquant.")
    end

    it "renders unauthorized when typ is not access" do
      token = JWT.encode(
        {
          sub: admin.id,
          typ: "refresh",
          exp: 1.hour.from_now.to_i,
          iat: Time.current.to_i,
          jti: SecureRandom.uuid
        },
        JwtConfig.secret,
        "HS256"
      )
      request.headers["Authorization"] = "Bearer #{token}"

      get :authenticate_user_probe

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["message"]).to eq("Token d'accès invalide ou manquant.")
    end

    it "renders unauthorized when the access token is expired" do
      token = JWT.encode(
        {
          sub: admin.id,
          typ: "access",
          exp: 1.hour.ago.to_i,
          iat: 2.hours.ago.to_i,
          jti: SecureRandom.uuid
        },
        JwtConfig.secret,
        "HS256"
      )
      request.headers["Authorization"] = "Bearer #{token}"

      get :authenticate_user_probe

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["message"]).to eq("Token d'accès invalide ou manquant.")
    end

    it "renders unauthorized when sub does not match any user" do
      token = Api::V1::Users::JwtAccessToken.encode(SecureRandom.uuid)
      request.headers["Authorization"] = "Bearer #{token}"

      get :authenticate_user_probe

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["message"]).to eq("Token d'accès invalide ou manquant.")
    end
  end

  describe "#bearer_token" do
    it "returns the stripped token after a Bearer Authorization header" do
      request.headers["Authorization"] = "Bearer   my.jwt.token  "

      get :bearer_token_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["token"]).to eq("my.jwt.token")
    end

    it "returns nil when Authorization is missing" do
      get :bearer_token_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["token"]).to be_nil
    end

    it "returns nil when Authorization does not start with Bearer" do
      request.headers["Authorization"] = "Token abc.def"

      get :bearer_token_probe

      expect(json_response["token"]).to be_nil
    end
  end

  describe "#raw_access_token" do
    let(:bearer_value) { "from-bearer.jwt" }
    let(:cookie_value) { "from-cookie.jwt" }

    it "returns the Bearer token when Authorization is set" do
      request.headers["Authorization"] = "Bearer #{bearer_value}"

      get :raw_access_token_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["raw"]).to eq(bearer_value)
    end

    it "returns the access cookie when there is no Bearer token" do
      request.cookies[JwtConfig::ACCESS_COOKIE_NAME] = cookie_value

      get :raw_access_token_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["raw"]).to eq(cookie_value)
    end

    it "prefers the Bearer token over the access cookie when both are present" do
      request.headers["Authorization"] = "Bearer #{bearer_value}"
      request.cookies[JwtConfig::ACCESS_COOKIE_NAME] = cookie_value

      get :raw_access_token_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["raw"]).to eq(bearer_value)
    end

    it "returns the cookie when Authorization is present but Bearer payload is blank" do
      request.headers["Authorization"] = "Bearer   "
      request.cookies[JwtConfig::ACCESS_COOKIE_NAME] = cookie_value

      get :raw_access_token_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["raw"]).to eq(cookie_value)
    end

    it "returns nil when neither Bearer nor cookie is present" do
      get :raw_access_token_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["raw"]).to be_nil
    end
  end
end
