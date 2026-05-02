# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Carts::ClearController", type: :request do
  before do
    CartSauce.delete_all
    Cart.delete_all
    Conditioning.delete_all
    Sauce.delete_all
    Category.delete_all
    User.delete_all
  end

  describe "DELETE /api/v1/carts" do
    it "removes all lines for guest cart but keeps cart record" do
      sauce = create(:sauce, name: "Cart Clear Guest")
      create(:conditioning, sauce: sauce, price: 5.50)

      conditioning = Conditioning.find_by!(sauce: sauce)
      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 2 },
           as: :json
      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["items"].first["sauce_image_url"]).to be_nil
      cart_id_before = response_json["cart"]["id"]

      delete api_v1_cart_url, as: :json

      expect(response).to have_http_status(:ok)
      payload = response_json
      expect(payload["message"]).to eq("Panier vidé.")
      expect(payload["cart"]["id"]).to eq(cart_id_before)
      expect(payload["cart"]["items"]).to be_empty
      expect(payload["cart"]["items_count"]).to eq(0)
      expect(payload["cart"]["total_amount"]).to eq(0.0)
      expect(CartSauce.count).to eq(0)
      expect(Cart.find(cart_id_before)).to be_present
    end

    it "clears a cart after lines with images (DELETE uses CartSerializer with request.base_url)" do
      sauce = create(:sauce, name: "Cart Clear With Thumbnail")
      sauce.image.attach(
        io: StringIO.new("x"),
        filename: "thumb.png",
        content_type: "image/png"
      )
      conditioning = create(:conditioning, sauce: sauce, price: 4.0)

      host! "clear-cart-img.test"
      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 1 },
           as: :json
      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["items"].first["sauce_image_url"]).to start_with("http://clear-cart-img.test")
      expect(response_json["cart"]["items"].first["sauce_image_url"]).to include("/rails/active_storage/")

      delete api_v1_cart_url, as: :json

      expect(response).to have_http_status(:ok)
      expect(response_json["message"]).to eq("Panier vidé.")
      expect(response_json["cart"]["items"]).to be_empty
      expect(response_json["cart"]["items_count"]).to eq(0)
      expect(response_json["cart"]["total_amount"]).to eq(0.0)
    end

    it "clears user cart lines when authenticated" do
      user = create(:user)
      sauce = create(:sauce, name: "Cart Clear Customer")
      create(:conditioning, sauce: sauce, price: 3.80)

      conditioning = Conditioning.find_by!(sauce: sauce)
      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 1 },
           headers: auth_headers_for(user),
           as: :json
      expect(response).to have_http_status(:ok)

      delete api_v1_cart_url, headers: auth_headers_for(user), as: :json

      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["user_id"]).to eq(user.id)
      expect(response_json["cart"]["items"]).to be_empty
      expect(Cart.find_by!(user: user).cart_sauces.count).to eq(0)
    end
  end
end
