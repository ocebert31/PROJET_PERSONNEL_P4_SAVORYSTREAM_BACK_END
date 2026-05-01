# frozen_string_literal: true

require "rails_helper"

RSpec.describe CartSauce, type: :model do
  before do
    CartSauce.delete_all
    Cart.delete_all
    Sauce.delete_all
    Category.delete_all
    User.delete_all
  end

  describe "valid cart_sauce" do
    it "persists with cart, sauce, conditioning, quantity and price" do
      cart_sauce = build(:cart_sauce, quantity: 2, price: 5.90)

      expect(cart_sauce.save).to be true
      expect(cart_sauce.reload.quantity).to eq(2)
      expect(cart_sauce.price.to_f).to eq(5.90)
      expect(cart_sauce.cart).to be_present
      expect(cart_sauce.sauce).to be_present
      expect(cart_sauce.conditioning).to be_present
    end

    it "rejects conditioning that does not match sauce" do
      sauce_a = create(:sauce)
      sauce_b = create(:sauce)
      conditioning_b = create(:conditioning, sauce: sauce_b)
      cart = create(:cart)

      cart_sauce = described_class.new(
        cart: cart,
        sauce: sauce_a,
        conditioning: conditioning_b,
        quantity: 1,
        price: 1.0
      )

      expect(cart_sauce.save).to be false
      expect(cart_sauce.errors[:conditioning_id]).to be_present
    end
  end

  describe "quantity" do
    it "rejects blank quantity" do
      cart_sauce = build(:cart_sauce, quantity: nil)

      expect(cart_sauce.save).to be false
      expect(cart_sauce.errors[:quantity]).to be_present
    end

    it "rejects non-integer quantity" do
      cart_sauce = build(:cart_sauce, quantity: 1.5)

      expect(cart_sauce.save).to be false
      expect(cart_sauce.errors[:quantity]).to be_present
    end

    it "rejects quantity equal to 0" do
      cart_sauce = build(:cart_sauce, quantity: 0)

      expect(cart_sauce.save).to be false
      expect(cart_sauce.errors[:quantity]).to be_present
    end

    it "accepts quantity greater than 0" do
      cart_sauce = build(:cart_sauce, quantity: 1)

      expect(cart_sauce.save).to be true
      expect(cart_sauce.reload.quantity).to eq(1)
    end
  end

  describe "price" do
    it "rejects blank price" do
      cart_sauce = build(:cart_sauce, price: nil)

      expect(cart_sauce.save).to be false
      expect(cart_sauce.errors[:price]).to be_present
    end

    it "rejects price lower than 0" do
      cart_sauce = build(:cart_sauce, price: -0.01)

      expect(cart_sauce.save).to be false
      expect(cart_sauce.errors[:price]).to be_present
    end

    it "accepts price equal to 0" do
      cart_sauce = build(:cart_sauce, price: 0)

      expect(cart_sauce.save).to be true
      expect(cart_sauce.reload.price.to_f).to eq(0.0)
    end
  end

  describe "associations" do
    it "belongs to cart, sauce and conditioning" do
      cart_sauce = create(:cart_sauce)

      expect(cart_sauce.cart).to be_present
      expect(cart_sauce.sauce).to be_present
      expect(cart_sauce.conditioning).to be_present
      expect(cart_sauce.cart.cart_sauces).to include(cart_sauce)
      expect(cart_sauce.sauce.cart_sauces).to include(cart_sauce)
    end
  end
end
