# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Carts::UpdateItemController", type: :request do
  before do
    CartSauce.delete_all
    Cart.delete_all
    Conditioning.delete_all
    Sauce.delete_all
    Category.delete_all
    User.delete_all
  end

  describe "PATCH /api/v1/carts/items/:id" do
    it "updates quantity when guest cart has the line" do
      sauce = create(:sauce, name: "Cart Update Guest")
      conditioning = create(:conditioning, sauce: sauce, price: 5.55)

      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 1 },
           as: :json
      expect(response).to have_http_status(:ok)
      line_id = response_json["cart"]["items"].first["id"]

      patch item_api_v1_cart_url(line_id), params: { quantity: 4 }, as: :json

      expect(response).to have_http_status(:ok)
      payload = response_json
      expect(payload["message"]).to eq("Quantité mise à jour.")
      item = payload["cart"]["items"].first
      expect(item["quantity"]).to eq(4)
      expect(item["unit_price"]).to eq(5.55)
      expect(item["line_total"]).to eq(22.20)
      expect(payload["cart"]["items_count"]).to eq(4)
      expect(payload["cart"]["total_amount"]).to eq(22.20)

      cart = Cart.where(user_id: nil).where.not(guest_id: nil).take
      expect(cart.cart_sauces.find(line_id).quantity).to eq(4)
    end

    it "removes line when quantity is 0" do
      sauce = create(:sauce, name: "Cart Update Zero")
      conditioning = create(:conditioning, sauce: sauce, price: 2.22)

      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 3 },
           as: :json
      line_id = response_json["cart"]["items"].first["id"]

      patch item_api_v1_cart_url(line_id), params: { quantity: 0 }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response_json["message"]).to eq("Article retiré du panier.")
      expect(response_json["cart"]["items"]).to be_empty
      expect(CartSauce.count).to eq(0)
    end

    it "updates authenticated user cart line" do
      user = create(:user)
      sauce = create(:sauce, name: "Cart Update Customer")
      conditioning = create(:conditioning, sauce: sauce, price: 9.90)

      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 2 },
           headers: auth_headers_for(user),
           as: :json
      expect(response).to have_http_status(:ok)
      line_id = response_json["cart"]["items"].first["id"]

      patch item_api_v1_cart_url(line_id),
            params: { quantity: 5 },
            headers: auth_headers_for(user),
            as: :json

      expect(response).to have_http_status(:ok)
      cart_payload = response_json["cart"]
      expect(cart_payload["user_id"]).to eq(user.id)
      item = cart_payload["items"].first
      expect(item["quantity"]).to eq(5)
      expect(item["unit_price"]).to eq(9.90)
      expect(item["line_total"]).to eq(49.50)
      expect(cart_payload["items_count"]).to eq(5)
      expect(cart_payload["total_amount"]).to eq(49.50)

      expect(Cart.find_by!(user: user).cart_sauces.find(line_id).quantity).to eq(5)
    end

    it "returns bad request when quantity is not an integer" do
      sauce = create(:sauce, name: "Cart Update Invalid Qty")
      conditioning = create(:conditioning, sauce: sauce, price: 1.0)

      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 1 },
           as: :json
      line_id = response_json["cart"]["items"].first["id"]

      patch item_api_v1_cart_url(line_id), params: { quantity: 1.5 }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response_json["message"]).to eq("quantity must be an integer")
    end

    it "returns not found when the line does not exist" do
      missing_line_id = "00000000-0000-0000-0000-000000000001"

      patch item_api_v1_cart_url(missing_line_id), params: { quantity: 1 }, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when line belongs to another cart" do
      sauce = create(:sauce)
      conditioning = create(:conditioning, sauce: sauce)
      other_cart = create(:cart)
      line = create(:cart_sauce, cart: other_cart, sauce: sauce, conditioning: conditioning)

      patch item_api_v1_cart_url(line.id), params: { quantity: 2 }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
