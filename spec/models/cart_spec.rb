# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cart, type: :model do
  before do
    CartSauce.delete_all
    Cart.delete_all
    User.delete_all
  end

  describe "valid cart" do
    it "persists a cart owned by a user" do
      cart = build(:cart)

      expect(cart.save).to be true
      expect(cart.reload.user).to be_present
      expect(cart.guest_id).to be_nil
    end

    it "persists a cart owned by a guest" do
      cart = build(:cart, :guest_owned)

      expect(cart.save).to be true
      expect(cart.reload.user).to be_nil
      expect(cart.guest_id).to be_present
    end
  end

  describe "owner validation" do
    it "rejects cart without user_id and guest_id" do
      cart = described_class.new

      expect(cart.save).to be false
      expect(cart.errors[:base]).to include("cart must belong to either a user or a guest")
    end

    it "rejects cart with both user_id and guest_id" do
      cart = build(:cart, guest_id: "guest-both")

      expect(cart.save).to be false
      expect(cart.errors[:base]).to include("cart must belong to either a user or a guest")
    end
  end

  describe "guest_id" do
    it "rejects duplicate guest_id" do
      create(:cart, :guest_owned, guest_id: "guest-duplicate")
      cart = build(:cart, :guest_owned, guest_id: "guest-duplicate")

      expect(cart.save).to be false
      expect(cart.errors[:guest_id]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a user when user-owned" do
      user = create(:user)
      cart = create(:cart, user: user, guest_id: nil)

      expect(cart.user).to eq(user)
      expect(user.cart).to eq(cart)
    end

    it "has many cart_sauces and sauces through cart_sauces" do
      cart = create(:cart)
      sauce = create(:sauce)
      conditioning = create(:conditioning, sauce: sauce)
      cart_sauce = create(:cart_sauce, cart: cart, sauce: sauce, conditioning: conditioning, quantity: 2, price: 5.90)

      expect(cart.cart_sauces).to include(cart_sauce)
      expect(cart.sauces).to include(sauce)
    end

    it "destroys dependent cart_sauces when the cart is destroyed" do
      cart = create(:cart)
      sauce = create(:sauce)
      conditioning = create(:conditioning, sauce: sauce)
      cart_sauce = create(:cart_sauce, cart: cart, sauce: sauce, conditioning: conditioning, quantity: 1, price: 3.50)

      expect { cart.destroy! }.to change(CartSauce, :count).by(-1)
      expect(CartSauce.find_by(id: cart_sauce.id)).to be_nil
    end
  end

  describe "CartSauce conditioning_matches_sauce validation" do
    it "adds an error when conditioning belongs to a different sauce than the line" do
      cart = create(:cart)
      sauce_a = create(:sauce)
      sauce_b = create(:sauce)
      conditioning_for_b = create(:conditioning, sauce: sauce_b)

      cart_sauce = CartSauce.new(
        cart: cart,
        sauce: sauce_a,
        conditioning: conditioning_for_b,
        quantity: 1,
        price: 1.0
      )

      expect(cart_sauce).not_to be_valid
      expect(cart_sauce.errors[:conditioning_id]).to include("does not belong to sauce")
    end

    it "is valid when conditioning belongs to the same sauce" do
      cart = create(:cart)
      sauce = create(:sauce)
      conditioning = create(:conditioning, sauce: sauce)

      cart_sauce = CartSauce.new(
        cart: cart,
        sauce: sauce,
        conditioning: conditioning,
        quantity: 1,
        price: conditioning.price
      )

      expect(cart_sauce).to be_valid
      expect(cart_sauce.save).to be true
    end
  end
end
