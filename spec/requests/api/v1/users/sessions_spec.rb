# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Users::SessionsController, type: :request do
  let(:password) { "password12" }
  let(:json_headers) { { "Content-Type" => "application/json" } }

  let!(:user) do
    User.create!(
      first_name: "Jane",
      last_name: "Doe",
      email: "jane@example.com",
      phone_number: "0612345678",
      password: password,
      password_confirmation: password
    )
  end

  before { UsersAuthentification.delete_all }

  describe "create" do
    context "nominal: valid email and password" do
      it "returns 200 with access token, sets refresh cookie, user payload, and expiry fields" do
        post api_v1_users_sessions_url,
             params: { email: "jane@example.com", password: password, remember_me: false }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["message"]).to eq("Connexion réussie.")
        expect(response_json["access_token"]).to be_present
        expect(response_json["access_expires_in"]).to eq(900)
        expect(response_json["remember_me"]).to be false
        expect(response_json["user"]["email"]).to eq("jane@example.com")
        expect(response.headers["Set-Cookie"]).to include("ss_refresh=")
        expect(UsersAuthentification.count).to eq(1)
        expect(UsersAuthentification.first.remember_me).to be false
      end
    end

    context "when logging in with phone_number instead of email" do
      it "returns 200 and resolves the same user" do
        post api_v1_users_sessions_url,
             params: { phone_number: "0612345678", password: password }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["user"]["email"]).to eq("jane@example.com")
      end
    end

    context "when rememberMe is true" do
      it "persists remember_me and sets a long refresh window" do
        post api_v1_users_sessions_url,
             params: { email: "jane@example.com", password: password, rememberMe: true }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["remember_me"]).to be true
        expires = Time.zone.parse(response_json["refresh_expires_at"])
        expect(expires).to be > 20.days.from_now
        expect(UsersAuthentification.first.remember_me).to be true
      end
    end

    context "when remember_me is explicitly false" do
      it "sets a shorter refresh window than the long-remember branch" do
        post api_v1_users_sessions_url,
             params: { email: "jane@example.com", password: password, remember_me: false }.to_json,
             headers: json_headers

        expires = Time.zone.parse(response_json["refresh_expires_at"])
        expect(expires).to be < 20.days.from_now
        expect(expires).to be > 5.days.from_now
      end
    end

    context "when both email and phone are provided" do
      it "returns 422 and does not create a refresh row" do
        post api_v1_users_sessions_url,
             params: { email: "jane@example.com", phone_number: "0612345678", password: password }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]["base"].first).to include("pas les deux")
        expect(UsersAuthentification.count).to eq(0)
      end
    end

    context "when neither email nor phone is provided" do
      it "returns 422" do
        post api_v1_users_sessions_url,
             params: { password: password }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]["base"].first).to include("requis")
      end
    end

    context "when password is wrong" do
      it "returns 401 with a generic message" do
        post api_v1_users_sessions_url,
             params: { email: "jane@example.com", password: "wrong" }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(response_json["message"]).to eq("Impossible de vous connecter. Vérifiez vos informations.")
      end
    end

    context "when no user matches the identifier" do
      it "returns 401" do
        post api_v1_users_sessions_url,
             params: { email: "nobody@example.com", password: password }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "refresh" do
    let(:perform_login) do
      post api_v1_users_sessions_url,
           params: { email: "jane@example.com", password: password }.to_json,
           headers: json_headers
      response_json
    end

    context "nominal: valid refresh_token after login" do
      it "returns 200 with a new access_token and expiry metadata" do
        first = perform_login
        access1 = first["access_token"]

        post refresh_api_v1_users_sessions_url,
             params: {}.to_json,
             headers: json_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["access_token"]).to be_present
        expect(response_json["access_token"]).not_to eq(access1)
        expect(response_json["access_expires_in"]).to eq(900)
      end
    end

    context "when refresh_token is invalid" do
      it "returns 401" do
        post refresh_api_v1_users_sessions_url,
             params: { refresh_token: "invalid" }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(response_json["message"]).to eq("Refresh token invalide ou expiré.")
      end
    end
  end

  describe "revoke" do
    let(:perform_login) do
      post api_v1_users_sessions_url,
           params: { email: "jane@example.com", password: password }.to_json,
           headers: json_headers
      response_json
    end

    context "nominal: valid refresh_token" do
      it "returns 204 and subsequent refresh with the same token is unauthorized" do
        perform_login

        post revoke_api_v1_users_sessions_url,
             params: {}.to_json,
             headers: json_headers

        expect(response).to have_http_status(:no_content)

        post refresh_api_v1_users_sessions_url,
             params: {}.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when refresh_token is invalid" do
      it "returns 401" do
        post revoke_api_v1_users_sessions_url,
             params: { refresh_token: "invalid" }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(response_json["message"]).to eq("Refresh token invalide ou expiré.")
      end
    end
  end

  def response_json
    JSON.parse(response.body)
  end
end
