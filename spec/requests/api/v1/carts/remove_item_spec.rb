# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Carts::RemoveItemController", type: :request do
  before do
    CartSauce.delete_all
    Cart.delete_all
    Conditioning.delete_all
    Sauce.delete_all
    Category.delete_all
    User.delete_all
  end

  describe "DELETE /api/v1/carts/items/:id" do
    it "removes one line from guest cart" do
      sauce = create(:sauce, name: "Cart Remove Guest")
      conditioning = create(:conditioning, sauce: sauce, price: 4.40)

      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 2 },
           as: :json
      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["items"].first["sauce_image_url"]).to be_nil
      line_id = response_json["cart"]["items"].first["id"]

      delete item_api_v1_cart_url(line_id), as: :json

      expect(response).to have_http_status(:ok)
      payload = response_json
      expect(payload["message"]).to eq("Article retiré du panier.")
      expect(payload["cart"]["items"]).to be_empty
      expect(payload["cart"]["items_count"]).to eq(0)
      expect(CartSauce.count).to eq(0)
    end

    it "removes a line from a cart with sauce image (serializer uses request.base_url)" do
      sauce = create(:sauce, name: "Cart Remove With Thumbnail")
      sauce.image.attach(
        io: StringIO.new("x"),
        filename: "thumb.png",
        content_type: "image/png"
      )
      conditioning = create(:conditioning, sauce: sauce, price: 5.0)

      host! "remove-item-img.test"
      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 1 },
           as: :json
      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["items"].first["sauce_image_url"]).to start_with("http://remove-item-img.test")
      expect(response_json["cart"]["items"].first["sauce_image_url"]).to include("/rails/active_storage/")
      line_id = response_json["cart"]["items"].first["id"]

      delete item_api_v1_cart_url(line_id), as: :json

      expect(response).to have_http_status(:ok)
      expect(response_json["message"]).to eq("Article retiré du panier.")
      expect(response_json["cart"]["items"]).to be_empty
      expect(response_json["cart"]["items_count"]).to eq(0)
      expect(CartSauce.count).to eq(0)
    end

    it "removes only the targeted line when same sauce has two conditionings" do
      sauce = create(:sauce, name: "Cart Remove Target Sauce")
      keep_c = create(:conditioning, sauce: sauce, volume: "250ml", price: 1.11)
      remove_c = create(:conditioning, sauce: sauce, volume: "500ml", price: 2.22)

      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: keep_c.id, quantity: 1 },
           as: :json
      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: remove_c.id, quantity: 3 },
           as: :json

      remove_line_id = response_json["cart"]["items"].find { |i| i["conditioning_id"] == remove_c.id }["id"]

      delete item_api_v1_cart_url(remove_line_id), as: :json

      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["items_count"]).to eq(1)

      cart = Cart.where(user_id: nil).where.not(guest_id: nil).take
      expect(cart.cart_sauces.find_by(conditioning_id: remove_c.id)).to be_nil
      expect(cart.cart_sauces.find_by!(conditioning_id: keep_c.id).quantity).to eq(1)
    end

    it "removes line when authenticated as user cart" do
      user = create(:user)
      sauce = create(:sauce, name: "Cart Remove Customer")
      conditioning = create(:conditioning, sauce: sauce, price: 6.66)

      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 1 },
           headers: auth_headers_for(user),
           as: :json
      expect(response).to have_http_status(:ok)
      line_id = response_json["cart"]["items"].first["id"]

      delete item_api_v1_cart_url(line_id), headers: auth_headers_for(user), as: :json

      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["user_id"]).to eq(user.id)
      expect(response_json["cart"]["guest_id"]).to be_nil
      expect(Cart.find_by!(user: user).cart_sauces.count).to eq(0)
    end

    it "returns not found when the line does not exist" do
      missing_line_id = "00000000-0000-0000-0000-000000000001"

      delete item_api_v1_cart_url(missing_line_id), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
