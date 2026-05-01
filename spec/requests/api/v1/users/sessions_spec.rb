# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users::Sessions", type: :request do
  let(:default_password) { "password12" }

  before do
    CartSauce.delete_all
    Cart.delete_all
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
        expect_set_cookie_line(JwtConfig::REFRESH_COOKIE_NAME)
        expect_set_cookie_line(JwtConfig::ACCESS_COOKIE_NAME)
        expect_cookie_path_matches_auth_cookie_path(JwtConfig::REFRESH_COOKIE_NAME)
        expect_cookie_path_matches_auth_cookie_path(JwtConfig::ACCESS_COOKIE_NAME)
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

      it "attaches guest cart to user on login and removes guest cookie" do
        guest_cart = Cart.create!(guest_id: "guest-123")

        submit_session(valid_login_payload.merge(guest_cart_id: "guest-123"))

        expect(response).to have_http_status(:ok)
        expect(guest_cart.reload.user_id).to eq(user.id)
        expect(guest_cart.guest_id).to be_nil
        expect_set_cookie_line("guest_cart_id")
        expect(set_cookie_line_for("guest_cart_id").downcase).to include("max-age=0")
      end

      it "keeps guest cart when both user and guest carts exist" do
        existing_user_cart = Cart.create!(user: user)
        guest_cart = Cart.create!(guest_id: "guest-456")

        submit_session(valid_login_payload.merge(guest_cart_id: "guest-456"))

        expect(response).to have_http_status(:ok)
        expect(Cart.find_by(id: existing_user_cart.id)).to be_nil
        expect(guest_cart.reload.user_id).to eq(user.id)
        expect(guest_cart.guest_id).to be_nil
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
        expect_set_cookie_line(JwtConfig::ACCESS_COOKIE_NAME)
        expect_cookie_path_matches_auth_cookie_path(JwtConfig::ACCESS_COOKIE_NAME)
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

    describe "GET /api/v1/users/sessions/me" do
      context "when authenticated" do
        it "returns the current user when Authorization Bearer is set" do
          token = Api::V1::Users::JwtAccessToken.encode(user.id)
          get me_api_v1_users_sessions_url, headers: { "Authorization" => "Bearer #{token}" }

          expect(response).to have_http_status(:ok)
          expect(response_json["user"]["email"]).to eq("jane@example.com")
        end

        it "returns the current user when the access cookie is present" do
          submit_session(valid_login_payload)

          get me_api_v1_users_sessions_url

          expect(response).to have_http_status(:ok)
          expect(response_json["user"]["email"]).to eq("jane@example.com")
        end
      end

      context "when not authenticated" do
        it "returns unauthorized" do
          get me_api_v1_users_sessions_url

          expect(response).to have_http_status(:unauthorized)
        end
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
    payload = credentials.deep_dup
    guest_cart_id = payload.delete(:guest_cart_id)

    headers = {}
    if guest_cart_id.present?
      # Rack ne voit pas toujours `cookies` avant une première requête ; envoyer le jeton invité en Cookie.
      headers["Cookie"] = "guest_cart_id=#{guest_cart_id}"
    end

    post api_v1_users_sessions_url, params: payload, as: :json, headers: headers
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

  # Une ligne Set-Cookie par jeton ; `set_access_cookie` / login posent `path: AUTH_COOKIE_PATH`.
  def expect_set_cookie_line(cookie_name)
    line = set_cookie_line_for(cookie_name)
    expect(line).to be_present, "expected Set-Cookie line for #{cookie_name}"
    line
  end

  def expect_cookie_path_matches_auth_cookie_path(cookie_name)
    line = set_cookie_line_for(cookie_name)
    expect(line).to be_present
    expected = "path=#{Api::V1::Users::SessionsController::AUTH_COOKIE_PATH}"
    expect(line.downcase).to include(expected.downcase)
  end

  def set_cookie_line_for(cookie_name)
    Array.wrap(response.get_header("Set-Cookie")).find do |h|
      h.to_s.start_with?("#{cookie_name}=")
    end
  end
end
