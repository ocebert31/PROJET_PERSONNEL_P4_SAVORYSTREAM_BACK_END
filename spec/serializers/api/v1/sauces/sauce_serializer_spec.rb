# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::SauceSerializer do
  let(:base_url) { "https://api.example.com" }

  def serialize(sauce, catalog_pricing: nil)
    described_class.call(sauce.reload, base_url: base_url, catalog_pricing: catalog_pricing)
  end

  describe ".call" do
    describe "without catalog_pricing" do
      it "returns the full payload with EUR TTC conditioning prices as strings and no currency metadata" do
        category = create(:category, name: "Hot")
        sauce = create(
          :sauce,
          category: category,
          name: "Sriracha",
          tagline: "Spicy",
          description: "Thai style",
          characteristic: "Heat",
          is_available: true
        )
        stock = create(:stock, sauce: sauce, quantity: 42)
        conditioning = create(:conditioning, sauce: sauce, volume: "250ml", price: 6.9)
        ingredient = create(:ingredient, sauce: sauce, name: "Chili", quantity: "12%")

        json = serialize(sauce)

        expect(json[:id]).to eq(sauce.id)
        expect(json[:name]).to eq("Sriracha")
        expect(json[:tagline]).to eq("Spicy")
        expect(json[:description]).to eq("Thai style")
        expect(json[:characteristic]).to eq("Heat")
        expect(json[:image_url]).to be_nil
        expect(json[:is_available]).to be true
        expect(json[:category]).to eq(id: category.id, name: "Hot")
        expect(json[:stock]).to eq(id: stock.id, quantity: 42)
        expect(json[:conditionings]).to eq(
          [ { id: conditioning.id, volume: "250ml", price: conditioning.price.to_s("F") } ]
        )
        expect(json[:ingredients]).to eq(
          [ { id: ingredient.id, name: "Chili", quantity: "12%" } ]
        )
        expect(json[:created_at]).to eq(sauce.created_at)
        expect(json[:updated_at]).to eq(sauce.updated_at)
        expect(json.key?(:display_currency)).to be(false)
        expect(json.key?(:prices_base_currency)).to be(false)
      end

      it "orders conditionings and ingredients by created_at ascending" do
        sauce = create(:sauce)
        cond_early = create(:conditioning, sauce: sauce, volume: "100ml", price: 4.0)
        cond_late = create(:conditioning, sauce: sauce, volume: "500ml", price: 9.0)
        cond_early.update_column(:created_at, 100.seconds.ago)
        cond_late.update_column(:created_at, 50.seconds.ago)

        ing_early = create(:ingredient, sauce: sauce, name: "First", quantity: "1%")
        ing_late = create(:ingredient, sauce: sauce, name: "Second", quantity: "2%")
        ing_early.update_column(:created_at, 100.seconds.ago)
        ing_late.update_column(:created_at, 50.seconds.ago)

        json = serialize(sauce)

        expect(json[:conditionings].map { |c| c[:volume] }).to eq(%w[100ml 500ml])
        expect(json[:ingredients].map { |i| i[:name] }).to eq(%w[First Second])
      end

      it "includes absolute image_url when the sauce has an image and base_url is present" do
        sauce = create(:sauce)
        sauce.image.attach(
          io: StringIO.new("x"),
          filename: "thumb.png",
          content_type: "image/png"
        )

        json = described_class.call(sauce.reload, base_url: "http://api.test", catalog_pricing: nil)
        url = json[:image_url]

        expect(url).to start_with("http://api.test")
        expect(url).to include("/rails/active_storage/")
      end
    end

    describe "with catalog_pricing" do
      let(:catalog_pricing) { { currency_iso: "USD", eur_multiplier: BigDecimal("1.08") } }

      it "multiplies EUR TTC conditioning prices and exposes display metadata" do
        sauce = create(:sauce, name: "Prix converti")
        create(:conditioning, sauce: sauce, volume: "250ml", price: 10)

        json = serialize(sauce, catalog_pricing: catalog_pricing)

        expect(json[:display_currency]).to eq("USD")
        expect(json[:prices_base_currency]).to eq("EUR")
        expect(json[:conditionings].first[:price]).to eq(
          Pricing::CatalogAmountConversion.convert_to_string(10, catalog_pricing)
        )
      end

      it "converts each conditioning price independently when several formats exist" do
        sauce = create(:sauce)
        create(:conditioning, sauce: sauce, volume: "250ml", price: 10.0)
        create(:conditioning, sauce: sauce, volume: "500ml", price: 5.0)

        json = serialize(sauce, catalog_pricing: catalog_pricing)

        expect(json[:conditionings].map { |c| c[:price] }).to eq(
          [
            Pricing::CatalogAmountConversion.convert_to_string(10.0, catalog_pricing),
            Pricing::CatalogAmountConversion.convert_to_string(5.0, catalog_pricing)
          ]
        )
      end

      it "omits display metadata when catalog_pricing is blank" do
        sauce = create(:sauce)
        create(:conditioning, sauce: sauce, volume: "250ml", price: 10.0)

        json = serialize(sauce, catalog_pricing: {})

        expect(json.key?(:display_currency)).to be(false)
        expect(json.key?(:prices_base_currency)).to be(false)
        expect(json[:conditionings].first[:price]).to eq("10.0")
      end
    end
  end

  describe ".image_url_for" do
    it "returns nil when base_url is blank" do
      sauce = create(:sauce)
      sauce.image.attach(
        io: StringIO.new("x"),
        filename: "thumb.png",
        content_type: "image/png"
      )

      expect(described_class.image_url_for(sauce.reload, base_url: nil)).to be_nil
      expect(described_class.image_url_for(sauce, base_url: "")).to be_nil
    end

    it "returns an absolute URL when base_url is present and an image is attached" do
      sauce = create(:sauce)
      sauce.image.attach(
        io: StringIO.new("x"),
        filename: "thumb.png",
        content_type: "image/png"
      )

      url = described_class.image_url_for(sauce.reload, base_url: "http://cart.test")

      expect(url).to start_with("http://cart.test")
      expect(url).to include("/rails/active_storage/")
    end

    it "returns nil when the sauce has no image" do
      sauce = create(:sauce)

      expect(described_class.image_url_for(sauce, base_url: base_url)).to be_nil
    end
  end
end
