# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Carts::CartSerializer do
  describe ".call" do
    it "returns an empty-items payload with zero aggregates for a cart with no lines" do
      cart = create(:cart)

      json = described_class.call(cart)

      expect(json[:id]).to eq(cart.id)
      expect(json[:user_id]).to eq(cart.user_id)
      expect(json[:guest_id]).to be_nil
      expect(json[:items_count]).to eq(0)
      expect(json[:total_amount]).to eq(0.0)
      expect(json[:items]).to eq([])
    end

    it "exposes guest_id and nil user_id on a guest-owned cart" do
      cart = create(:cart, :guest_owned)

      json = described_class.call(cart)

      expect(json[:user_id]).to be_nil
      expect(json[:guest_id]).to eq(cart.guest_id)
      expect(json[:items]).to eq([])
    end

    it "lists lines sorted by cart_sauce created_at ascending" do
      cart = create(:cart)
      sauce_early = create(:sauce, name: "First in time")
      sauce_late = create(:sauce, name: "Second in time")
      cond_early = create(:conditioning, sauce: sauce_early, volume: "250ml", price: 1.0)
      cond_late = create(:conditioning, sauce: sauce_late, volume: "250ml", price: 1.0)

      early = create(:cart_sauce, cart: cart, sauce: sauce_early, conditioning: cond_early, quantity: 1, price: 1.0)
      late = create(:cart_sauce, cart: cart, sauce: sauce_late, conditioning: cond_late, quantity: 1, price: 1.0)
      early.update_column(:created_at, 100.seconds.ago)
      late.update_column(:created_at, 50.seconds.ago)

      json = described_class.call(cart.reload)

      expect(json[:items].map { |row| row[:sauce_name] }).to eq(
        [ "First in time", "Second in time" ]
      )
    end

    it "maps sauce and conditioning fields and computes aggregates" do
      cart = create(:cart)
      sauce_a = create(:sauce, name: "Nuoc mam")
      sauce_b = create(:sauce, name: "Miso glaze")
      cond_a = create(:conditioning, sauce: sauce_a, volume: "250ml", price: 4.50)
      cond_b = create(:conditioning, sauce: sauce_b, volume: "400ml", price: 2.25)

      line_a = create(:cart_sauce, cart: cart, sauce: sauce_a, conditioning: cond_a, quantity: 2, price: 4.50)
      line_b = create(:cart_sauce, cart: cart, sauce: sauce_b, conditioning: cond_b, quantity: 3, price: 2.25)

      json = described_class.call(cart.reload)

      expect(json[:items_count]).to eq(5)
      expect(json[:total_amount]).to eq(15.75)

      expect(json[:items]).to eq(
        [
          {
            id: line_a.id,
            sauce_id: sauce_a.id,
            sauce_name: "Nuoc mam",
            conditioning_id: cond_a.id,
            volume: "250ml",
            quantity: 2,
            unit_price: 4.5,
            line_total: 9.0
          },
          {
            id: line_b.id,
            sauce_id: sauce_b.id,
            sauce_name: "Miso glaze",
            conditioning_id: cond_b.id,
            volume: "400ml",
            quantity: 3,
            unit_price: 2.25,
            line_total: 6.75
          }
        ]
      )
    end

    it "rounds total_amount to two decimal places across lines" do
      cart = create(:cart)
      sauce_one = create(:sauce)
      sauce_two = create(:sauce)
      cond_one = create(:conditioning, sauce: sauce_one, volume: "100ml", price: 0.01)
      cond_two = create(:conditioning, sauce: sauce_two, volume: "100ml", price: 0.01)

      create(:cart_sauce, cart: cart, sauce: sauce_one, conditioning: cond_one, quantity: 2, price: 0.01)
      create(:cart_sauce, cart: cart, sauce: sauce_two, conditioning: cond_two, quantity: 1, price: 0.01)

      json = described_class.call(cart.reload)

      expect(json[:total_amount]).to eq(0.03)
      expect(json[:items_count]).to eq(3)
    end
  end
end
