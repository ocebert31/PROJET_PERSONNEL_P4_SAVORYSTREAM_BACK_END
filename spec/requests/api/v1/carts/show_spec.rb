# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Carts::ShowController", type: :request do
  before do
    CartSauce.delete_all
    Cart.delete_all
    Conditioning.delete_all
    Sauce.delete_all
    Category.delete_all
    User.delete_all
  end

  describe "GET /api/v1/carts" do
    it "returns guest cart, sets guest cookie, and is idempotent" do
      get api_v1_cart_url

      expect(response).to have_http_status(:ok)
      payload = response_json["cart"]
      expect(payload["user_id"]).to be_nil
      expect(payload["guest_id"]).to be_present
      expect(Array.wrap(response.get_header("Set-Cookie")).join).to include("guest_cart_id=")

      guest_id = payload["guest_id"]
      cart_id = payload["id"]

      get api_v1_cart_url

      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["id"]).to eq(cart_id)
      expect(response_json["cart"]["guest_id"]).to eq(guest_id)
      expect(Cart.where(guest_id: guest_id).count).to eq(1)
    end

    it "returns user-owned cart and stays stable across GET requests" do
      user = create(:user)

      get api_v1_cart_url, headers: auth_headers_for(user)
      expect(response).to have_http_status(:ok)

      cart_id_first = response_json["cart"]["id"]
      expect(response_json["cart"]["user_id"]).to eq(user.id)
      expect(response_json["cart"]["guest_id"]).to be_nil

      get api_v1_cart_url, headers: auth_headers_for(user)
      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["id"]).to eq(cart_id_first)
      expect(Cart.where(user: user).count).to eq(1)
    end
  end
end
