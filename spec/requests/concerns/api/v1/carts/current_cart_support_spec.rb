# frozen_string_literal: true

require "rails_helper"
require "jwt"

RSpec.describe Api::V1::Carts::CurrentCartSupport, type: :controller do
  controller(ApplicationController) do
    include Api::V1::Carts::CurrentCartSupport

    def current_cart_probe
      cart = current_cart
      render json: {
        id: cart.id,
        user_id: cart.user_id,
        guest_id: cart.guest_id
      }, status: :ok
    end

    def quantity_probe
      value = item_quantity_param(default: 7)
      render json: { quantity: value }, status: :ok
    end

    def guest_cookie_probe
      gid = ensure_guest_cart_cookie!
      render json: { guest_id: gid }, status: :ok
    end
  end

  before do
    CartSauce.delete_all
    Cart.delete_all
    Conditioning.delete_all
    Sauce.delete_all
    Category.delete_all
    User.delete_all

    routes.draw do
      get :current_cart_probe, to: "anonymous#current_cart_probe"
      get :quantity_probe, to: "anonymous#quantity_probe"
      get :guest_cookie_probe, to: "anonymous#guest_cookie_probe"
    end
  end

  def json_response
    response.parsed_body
  end

  def set_cookie_header
    Array.wrap(response.get_header("Set-Cookie")).join
  end

  describe "#current_cart" do
    context "with an authenticated access token" do
      it "returns user cart when a valid Bearer access token exists" do
        cart = create(:cart)
        token = Api::V1::Users::JwtAccessToken.encode(cart.user.id)
        request.headers["Authorization"] = "Bearer #{token}"

        get :current_cart_probe

        expect(response).to have_http_status(:ok)
        expect(json_response["user_id"]).to eq(cart.user.id)
        expect(json_response["guest_id"]).to be_nil
      end

      it "reads access token from access cookie when Authorization is missing" do
        cart = create(:cart)
        token = Api::V1::Users::JwtAccessToken.encode(cart.user.id)
        request.cookies[JwtConfig::ACCESS_COOKIE_NAME] = token

        get :current_cart_probe

        expect(response).to have_http_status(:ok)
        expect(json_response["user_id"]).to eq(cart.user.id)
      end
    end

    context "with guest cart cookie pointing at an existing guest cart" do
      let!(:guest_cart) { create(:cart, :stable_guest) }

      it "returns that guest cart without creating duplicates" do
        request.cookies[Api::V1::Carts::CurrentCartSupport::CART_COOKIE_NAME] = "guest-stable"

        get :current_cart_probe

        expect(response).to have_http_status(:ok)
        expect(json_response["id"]).to eq(guest_cart.id)
        expect(Cart.where(guest_id: "guest-stable").count).to eq(1)
      end
    end

    context "without guest cart cookie and without auth" do
      it "creates guest cookie and a new guest cart" do
        expect(Cart.count).to eq(0)

        get :current_cart_probe

        expect(response).to have_http_status(:ok)
        expect(set_cookie_header).to include("#{Api::V1::Carts::CurrentCartSupport::CART_COOKIE_NAME}=")

        guest_id = json_response["guest_id"]
        expect(guest_id).to be_present
        expect(json_response["user_id"]).to be_nil

        expect(Cart.find_by!(guest_id: guest_id)).to be_present
        expect(Cart.where(user_id: nil).where.not(guest_id: nil).count).to eq(1)
      end
    end
  end

  describe "#ensure_guest_cart_cookie!" do
    let(:cookie_name) { Api::V1::Carts::CurrentCartSupport::CART_COOKIE_NAME }

    it "issues a UUID and sets HttpOnly lax cookie on path / when absent" do
      get :guest_cookie_probe

      expect(response).to have_http_status(:ok)
      guest_id = json_response["guest_id"]
      expect(guest_id).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)

      header = set_cookie_header
      expect(header).to include("#{cookie_name}=#{guest_id}")
      expect(header).to include("path=/")
      expect(header.downcase).to include("httponly")
      expect(header).to match(/samesite=lax/i)
    end

    it "reuses cookie value when already present (refreshes Set-Cookie)" do
      request.cookies[cookie_name] = "guest-reuse-me"

      get :guest_cookie_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["guest_id"]).to eq("guest-reuse-me")
      expect(set_cookie_header).to include("#{cookie_name}=guest-reuse-me")
    end

    it "generates a new id when cookie is blank white space only" do
      request.cookies[cookie_name] = "   "

      get :guest_cookie_probe

      expect(response).to have_http_status(:ok)
      new_id = json_response["guest_id"]
      expect(new_id).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      expect(set_cookie_header).to include("#{cookie_name}=#{new_id}")
    end

    it "generates new id when cookie is empty string" do
      request.cookies[cookie_name] = ""

      get :guest_cookie_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["guest_id"]).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end

    it "does not include Secure flag in non-production environments" do
      get :guest_cookie_probe

      expect(set_cookie_header).not_to match(/;\s*secure\b/i)
    end
  end

  describe "#item_quantity_param" do
    it "parses integer string quantities" do
      get :quantity_probe, params: { quantity: "12" }

      expect(response).to have_http_status(:ok)
      expect(json_response["quantity"]).to eq(12)
    end

    it "rejects decimal floats" do
      get :quantity_probe, params: { quantity: 1.25 }

      expect(response).to have_http_status(:bad_request)
      expect(json_response["message"]).to eq("quantity must be an integer")
    end

    it "returns default when quantity is omitted" do
      get :quantity_probe

      expect(response).to have_http_status(:ok)
      expect(json_response["quantity"]).to eq(7)
    end
  end
end
