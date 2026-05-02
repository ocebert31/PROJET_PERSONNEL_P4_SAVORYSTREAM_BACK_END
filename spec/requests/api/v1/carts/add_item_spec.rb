# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Carts::AddItemController", type: :request do
  before do
    CartSauce.delete_all
    Cart.delete_all
    Conditioning.delete_all
    Sauce.delete_all
    Category.delete_all
    User.delete_all
  end

  def post_add_item(payload)
    post items_api_v1_cart_url, params: payload, as: :json
  end

  describe "POST /api/v1/carts/items" do
    it "creates cart line when guest adds a sauce once" do
      sauce = create(:sauce, name: "Cart Add One")
      conditioning = create(:conditioning, sauce: sauce, volume: "250ml", price: 6.90)

      post_add_item(sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 2)

      expect(response).to have_http_status(:ok)
      payload = response_json
      expect(payload["message"]).to eq("Article ajouté au panier.")
      expect(payload["cart"]["items_count"]).to eq(2)

      item = payload["cart"]["items"].first
      expect(item["id"]).to be_present
      expect(item["sauce_id"]).to eq(sauce.id)
      expect(item["conditioning_id"]).to eq(conditioning.id)
      expect(item["volume"]).to eq("250ml")
      expect(item["quantity"]).to eq(2)
      expect(item["unit_price"]).to eq(6.9)
      expect(item["sauce_image_url"]).to be_nil

      cart = Cart.where(user_id: nil).where.not(guest_id: nil).take
      expect(cart).to be_present
      expect(CartSauce.where(cart: cart, conditioning: conditioning).count).to eq(1)
    end

    it "returns an absolute sauce_image_url when the sauce has an image (uses request.base_url)" do
      sauce = create(:sauce, name: "Cart Add With Thumbnail")
      sauce.image.attach(
        io: StringIO.new("x"),
        filename: "thumb.png",
        content_type: "image/png"
      )
      conditioning = create(:conditioning, sauce: sauce, volume: "250ml", price: 5.0)

      host! "add-item-img.test"
      post_add_item(sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 1)

      expect(response).to have_http_status(:ok)
      url = response_json["cart"]["items"].first["sauce_image_url"]
      expect(url).to start_with("http://add-item-img.test")
      expect(url).to include("/rails/active_storage/")
    end

    it "increments quantity when posting the same conditioning again" do
      sauce = create(:sauce, name: "Cart Add Merge")
      conditioning = create(:conditioning, sauce: sauce, price: 4.50)

      post_add_item(sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 1)
      expect(response).to have_http_status(:ok)

      post_add_item(sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 3)
      expect(response).to have_http_status(:ok)

      expect(response_json["cart"]["items"].size).to eq(1)
      expect(response_json["cart"]["items"].first["quantity"]).to eq(4)
    end

    it "creates separate lines for two conditionings of the same sauce" do
      sauce = create(:sauce, name: "Cart Add Multi Format")
      small = create(:conditioning, sauce: sauce, volume: "250ml", price: 6.50)
      large = create(:conditioning, sauce: sauce, volume: "500ml", price: 11.90)

      post_add_item(sauce_id: sauce.id, conditioning_id: small.id, quantity: 1)
      expect(response).to have_http_status(:ok)
      post_add_item(sauce_id: sauce.id, conditioning_id: large.id, quantity: 2)
      expect(response).to have_http_status(:ok)

      items = response_json["cart"]["items"]
      expect(items.size).to eq(2)
      expect(items.map { |i| i["conditioning_id"] }).to contain_exactly(small.id, large.id)
      expect(response_json["cart"]["items_count"]).to eq(3)
    end

    it "adds sauce to the user-owned cart when authenticated" do
      user = create(:user)
      sauce = create(:sauce, name: "Cart Add Customer")
      conditioning = create(:conditioning, sauce: sauce, price: 7.10)

      post items_api_v1_cart_url,
           params: { sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 3 },
           headers: auth_headers_for(user),
           as: :json

      expect(response).to have_http_status(:ok)
      payload = response_json
      expect(payload["cart"]["user_id"]).to eq(user.id)
      expect(payload["cart"]["guest_id"]).to be_nil
      expect(payload["cart"]["items_count"]).to eq(3)

      cart = Cart.find_by!(user: user)
      line = cart.cart_sauces.find_by!(conditioning: conditioning)
      expect(line.quantity).to eq(3)
      expect(line.price.to_f).to eq(7.10)
    end

    it "uses the chosen conditioning price as unit_price snapshot" do
      sauce = create(:sauce, name: "Cart Add Pricing")
      expensive = create(:conditioning, sauce: sauce, volume: "500ml", price: 11.90)
      create(:conditioning, sauce: sauce, volume: "250ml", price: 6.50)

      post_add_item(sauce_id: sauce.id, conditioning_id: expensive.id, quantity: 1)

      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["items"].first["unit_price"]).to eq(11.9)
    end

    it "defaults quantity to 1 when omitted" do
      sauce = create(:sauce, name: "Cart Default Qty")
      conditioning = create(:conditioning, sauce: sauce)

      post_add_item(sauce_id: sauce.id, conditioning_id: conditioning.id)

      expect(response).to have_http_status(:ok)
      expect(response_json["cart"]["items"].first["quantity"]).to eq(1)
    end

    it "returns bad request when conditioning_id is missing" do
      sauce = create(:sauce, name: "Cart Missing Conditioning")

      post_add_item(sauce_id: sauce.id, quantity: 1)

      expect(response).to have_http_status(:bad_request)
      expect(response_json["message"]).to eq("conditioning_id is required")
    end

    it "returns bad request when quantity is not an integer" do
      sauce = create(:sauce, name: "Cart Invalid Qty")
      conditioning = create(:conditioning, sauce: sauce)

      post_add_item(sauce_id: sauce.id, conditioning_id: conditioning.id, quantity: 1.2)

      expect(response).to have_http_status(:bad_request)
      expect(response_json["message"]).to eq("quantity must be an integer")
    end

    it "returns not found for unknown sauce id" do
      unknown_id = "00000000-0000-0000-0000-000000000001"
      conditioning = create(:conditioning)

      post_add_item(sauce_id: unknown_id, conditioning_id: conditioning.id)

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when conditioning does not belong to sauce" do
      sauce = create(:sauce, name: "Cart Wrong Conditioning")
      other_conditioning = create(:conditioning)

      post_add_item(sauce_id: sauce.id, conditioning_id: other_conditioning.id, quantity: 1)

      expect(response).to have_http_status(:not_found)
    end
  end
end
