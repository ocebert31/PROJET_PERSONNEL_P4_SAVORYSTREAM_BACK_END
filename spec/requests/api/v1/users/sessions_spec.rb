# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users::Sessions", type: :request do
  let(:default_password) { "password12" }

  before do
    User.delete_all
    UsersAuthentification.delete_all
  end

  let!(:user) do
    User.create!(
      first_name: "Jane",
      last_name: "Doe",
      email: "jane@example.com",
      phone_number: "0612345678",
      password: default_password,
      password_confirmation: default_password
    )
  end

  describe "POST /api/v1/users/sessions" do
    context "when login succeeds" do
      it "creates a refresh session, sets cookie, and returns access token and user payload" do
        expect do
          submit_session(valid_login_payload)
        end.to change(UsersAuthentification, :count).by(1)

        expect(response).to have_http_status(:ok)
        payload = response_json
        expect(payload["message"]).to eq("Connexion réussie.")
        expect(payload["access_token"]).to be_present
        expect(payload["access_expires_in"]).to eq(900)
        expect(payload["remember_me"]).to be false
        expect(payload["user"]["email"]).to eq("jane@example.com")
        expect(response.headers["Set-Cookie"]).to include("ss_refresh=")
        expect(UsersAuthentification.first.remember_me).to be false
      end

      it "resolves the user when phone_number is given instead of email" do
        submit_session({ phone_number: "0612345678", password: default_password })

        expect(response).to have_http_status(:ok)
        expect(response_json["user"]["email"]).to eq("jane@example.com")
      end

      it "persists remember_me and extends refresh expiry when rememberMe is true" do
        submit_session(valid_login_payload.merge(rememberMe: true))

        expect(response).to have_http_status(:ok)
        payload = response_json
        expect(payload["remember_me"]).to be true
        expires = Time.zone.parse(payload["refresh_expires_at"])
        expect(expires).to be > 20.days.from_now
        expect(UsersAuthentification.first.remember_me).to be true
      end

      it "uses a shorter refresh window when remember_me is false" do
        submit_session(valid_login_payload)

        expires = Time.zone.parse(response_json["refresh_expires_at"])
        expect(expires).to be < 20.days.from_now
        expect(expires).to be > 5.days.from_now
      end
    end

    context "when identification is invalid" do
      it "returns unprocessable entity with an errors payload" do
        expect do
          submit_session({ password: default_password })
        end.not_to change(UsersAuthentification, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to be_a(Hash)
        expect(response_json["errors"]).to be_present
      end
    end
  end

  describe "POST /api/v1/users/sessions/refresh" do
    context "when refresh succeeds" do
      it "returns a new access_token and expiry metadata" do
        submit_session(valid_login_payload)
        access_before = response_json["access_token"]

        submit_refresh

        expect(response).to have_http_status(:ok)
        payload = response_json
        expect(payload["access_token"]).to be_present
        expect(payload["access_token"]).not_to eq(access_before)
        expect(payload["access_expires_in"]).to eq(900)
      end
    end

    context "when refresh fails" do
      it "returns unauthorized when the refresh token is invalid" do
        submit_refresh({ refresh_token: "invalid" })

        expect(response).to have_http_status(:unauthorized)
        expect(response_json["message"]).to eq("Refresh token invalide ou expiré.")
      end
    end
  end

  describe "POST /api/v1/users/sessions/revoke" do
    context "when revoke succeeds" do
      it "returns no content and the refresh token can no longer be used" do
        submit_session(valid_login_payload)

        submit_revoke

        expect(response).to have_http_status(:no_content)

        submit_refresh

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when revoke fails" do
      it "returns unauthorized when the refresh token is invalid" do
        submit_revoke({ refresh_token: "invalid" })

        expect(response).to have_http_status(:unauthorized)
        expect(response_json["message"]).to eq("Refresh token invalide ou expiré.")
      end
    end
  end

  def submit_session(credentials)
    post api_v1_users_sessions_url, params: credentials, as: :json
  end

  def submit_refresh(params = {})
    post refresh_api_v1_users_sessions_url, params: params, as: :json
  end

  def submit_revoke(params = {})
    post revoke_api_v1_users_sessions_url, params: params, as: :json
  end

  def valid_login_payload(overrides = {})
    {
      email: "jane@example.com",
      password: default_password,
      remember_me: false
    }.merge(overrides)
  end
end
