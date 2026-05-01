# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sauce, type: :model do
  before do
    CartSauce.delete_all
    Cart.delete_all
    Ingredient.delete_all
    Conditioning.delete_all
    Stock.delete_all
    User.delete_all
    Sauce.delete_all
    Category.delete_all
  end

  describe "valid sauce" do
    it "persists a sauce with name, tagline, category, and availability" do
      sauce = build(:sauce, name: "Sriracha Spec", tagline: "Hot and tasty.")

      expect(sauce.save).to be true
      sauce.reload
      expect(sauce.name).to eq("Sriracha Spec")
      expect(sauce.tagline).to eq("Hot and tasty.")
      expect(sauce.category).to be_present
      expect(sauce.is_available).to be true
    end
  end

  describe "name" do
    it "rejects blank name" do
      sauce = build(:sauce, name: "")
      expect(sauce.save).to be false
      expect(sauce.errors[:name]).to be_present
    end

    it "rejects name longer than 50 characters" do
      sauce = build(:sauce, name: "a" * 51)
      expect(sauce.save).to be false
      expect(sauce.errors[:name]).to be_present
    end

    it "accepts name exactly 50 characters" do
      sauce = build(:sauce, name: "a" * 50)
      expect(sauce.save).to be true
      expect(sauce.reload.name.length).to eq(50)
    end

    it "rejects duplicate name" do
      category = create(:category)
      create(:sauce, name: "UniqueSauceName", category: category)

      sauce = build(:sauce, name: "UniqueSauceName", category: category)
      expect(sauce.save).to be false
      expect(sauce.errors[:name]).to be_present
    end
  end

  describe "tagline" do
    it "rejects blank tagline" do
      sauce = build(:sauce, tagline: "")
      expect(sauce.save).to be false
      expect(sauce.errors[:tagline]).to be_present
    end

    it "rejects tagline longer than 120 characters" do
      sauce = build(:sauce, tagline: "a" * 121)
      expect(sauce.save).to be false
      expect(sauce.errors[:tagline]).to be_present
    end

    it "accepts tagline exactly 120 characters" do
      sauce = build(:sauce, tagline: "a" * 120)
      expect(sauce.save).to be true
      expect(sauce.reload.tagline.length).to eq(120)
    end
  end

  describe "characteristic" do
    it "accepts blank characteristic" do
      sauce = build(:sauce, characteristic: "")
      expect(sauce.save).to be true
    end

    it "rejects characteristic longer than 255 characters" do
      sauce = build(:sauce, characteristic: "a" * 256)
      expect(sauce.save).to be false
      expect(sauce.errors[:characteristic]).to be_present
    end

    it "accepts characteristic exactly 255 characters" do
      sauce = build(:sauce, characteristic: "a" * 255)
      expect(sauce.save).to be true
      expect(sauce.reload.characteristic.length).to eq(255)
    end
  end

  describe "is_available" do
    it "accepts true" do
      sauce = build(:sauce, is_available: true)
      expect(sauce.save).to be true
      expect(sauce.reload.is_available).to be true
    end

    it "accepts false" do
      sauce = build(:sauce, is_available: false)
      expect(sauce.save).to be true
      expect(sauce.reload.is_available).to be false
    end

    it "persists with true when the attribute is omitted (schema default)" do
      category = create(:category)
      sauce = described_class.new(
        name: "DefaultAvail #{SecureRandom.hex(4)}",
        tagline: "Tagline for default availability.",
        category: category
      )
      expect(sauce.save).to be true
      expect(sauce.reload.is_available).to be true
    end

    it "rejects nil when explicitly assigned" do
      sauce = build(:sauce)
      sauce.is_available = nil
      expect(sauce.save).to be false
      expect(sauce.errors[:is_available]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a category" do
      category = create(:category)
      sauce = create(:sauce, category: category)

      expect(sauce.category).to eq(category)
      expect(category.sauces).to include(sauce)
    end

    it "rejects save without a category" do
      sauce = build(:sauce, category: nil)
      expect(sauce.save).to be false
      expect(sauce.errors[:category]).to be_present
    end

    it "has many conditionings" do
      sauce = create(:sauce)
      create(:conditioning, sauce: sauce, volume: "250ml", price: 6.9)
      create(:conditioning, sauce: sauce, volume: "500ml", price: 11.9)

      expect(sauce.conditionings.count).to eq(2)
      expect(sauce.conditionings.pluck(:volume)).to contain_exactly("250ml", "500ml")
    end

    it "has many ingredients" do
      sauce = create(:sauce)
      create(:ingredient, sauce: sauce, name: "Piment", quantity: "30%")
      create(:ingredient, sauce: sauce, name: "Vinaigre", quantity: "10%")

      expect(sauce.ingredients.count).to eq(2)
      expect(sauce.ingredients.pluck(:name)).to contain_exactly("Piment", "Vinaigre")
    end

    it "has one stock" do
      sauce = create(:sauce)
      stock = create(:stock, sauce: sauce, quantity: 42)

      expect(sauce.stock).to eq(stock)
    end

    it "has many cart_sauces and carts through cart_sauces" do
      sauce = create(:sauce)
      conditioning = create(:conditioning, sauce: sauce, volume: "250ml", price: 6.9)
      cart = create(:cart)
      cart_sauce = create(:cart_sauce, cart: cart, sauce: sauce, conditioning: conditioning, quantity: 2, price: 5.90)

      expect(sauce.cart_sauces).to include(cart_sauce)
      expect(sauce.carts).to include(cart)
    end

    it "destroys dependent conditionings, ingredients, and stock when the sauce is destroyed" do
      sauce = create(:sauce)
      create(:conditioning, sauce: sauce, volume: "250ml", price: 6.9)
      create(:ingredient, sauce: sauce, name: "Sel", quantity: "1%")
      create(:stock, sauce: sauce, quantity: 5)

      expect { sauce.destroy! }.not_to raise_error

      expect(Conditioning.find_by(sauce_id: sauce.id)).to be_nil
      expect(Ingredient.find_by(sauce_id: sauce.id)).to be_nil
      expect(Stock.find_by(sauce_id: sauce.id)).to be_nil
    end

    it "destroys dependent cart_sauces when the sauce is destroyed" do
      sauce = create(:sauce)
      conditioning = create(:conditioning, sauce: sauce, volume: "250ml", price: 6.9)
      cart = create(:cart)
      cart_sauce = create(:cart_sauce, cart: cart, sauce: sauce, conditioning: conditioning, quantity: 1, price: 3.50)

      expect { sauce.destroy! }.not_to raise_error
      expect(CartSauce.find_by(id: cart_sauce.id)).to be_nil
    end
  end
end
