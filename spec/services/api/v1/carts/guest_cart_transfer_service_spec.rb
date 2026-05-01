# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Carts::GuestCartTransferService do
  describe "#call" do
    it "returns false when guest_id is blank or whitespace-only" do
      user = create(:user)

      expect(described_class.new(user: user, guest_id: "").call).to be false
      expect(described_class.new(user: user, guest_id: "   ").call).to be false
      expect(described_class.new(user: user, guest_id: nil).call).to be false
    end

    it "returns false when no cart exists for guest_id (no mutation)" do
      user = create(:user)
      create(:cart, user: user)

      outcome = described_class.new(user: user, guest_id: SecureRandom.uuid).call

      expect(outcome).to be false
      expect(user.reload.cart).to be_present
      expect(Cart.count).to eq(1)
    end

    it "attaches the guest cart to the user when the user had no cart" do
      user = create(:user)
      guest_cart = create(:cart, :guest_owned, guest_id: "guest-xfer-1")

      outcome = described_class.new(user: user, guest_id: "guest-xfer-1").call

      expect(outcome).to be true
      guest_cart.reload
      expect(guest_cart.user_id).to eq(user.id)
      expect(guest_cart.guest_id).to be_nil
      expect(user.reload.cart&.id).to eq(guest_cart.id)
      expect(Cart.count).to eq(1)
    end

    it "destroys the existing user-owned cart before attaching guest cart when separate" do
      user = create(:user)
      old_cart = create(:cart, user: user)
      old_line = create(:cart_sauce, cart: old_cart, quantity: 1, price: 9.99)

      guest_cart = create(:cart, :guest_owned, guest_id: "guest-xfer-2")
      kept_line = create(:cart_sauce, cart: guest_cart, quantity: 2, price: 5.00)

      outcome = described_class.new(user: user, guest_id: "guest-xfer-2").call

      expect(outcome).to be true
      expect(Cart.find_by(id: old_cart.id)).to be_nil
      expect(CartSauce.find_by(id: old_line.id)).to be_nil

      guest_cart.reload
      expect(guest_cart.user_id).to eq(user.id)
      expect(guest_cart.guest_id).to be_nil

      kept_line.reload
      expect(kept_line.cart_id).to eq(guest_cart.id)

      expect(user.reload.cart).to have_attributes(id: guest_cart.id)
    end
  end
end
