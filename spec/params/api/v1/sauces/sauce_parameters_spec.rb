# frozen_string_literal: true

require "rails_helper"
require "rack/test"

RSpec.describe Api::V1::Sauces::SauceParameters do
  def ac_params(hash)
    ActionController::Parameters.new(hash)
  end

  describe "#permitted" do
    it "permits scalars, nested stock, conditionings, ingredients, and camelCase keys" do
      permitted = described_class.new(
        ac_params(
          name: "Sriracha",
          stock: { quantity: 5 },
          conditionings: [ { volume: "250ml", price: "6.9" } ],
          ingredients: [ { name: "Piment", quantity: "30%" } ],
          categoryId: "uuid-1"
        )
      ).permitted

      expect(permitted[:name]).to eq("Sriracha")
      expect(permitted[:stock].to_unsafe_h).to eq("quantity" => 5)
      expect(permitted[:conditionings].first.to_unsafe_h).to eq("volume" => "250ml", "price" => "6.9")
      expect(permitted[:ingredients].first.to_unsafe_h).to eq("name" => "Piment", "quantity" => "30%")
      expect(permitted[:categoryId]).to eq("uuid-1")
    end

    it "memoizes permit and drops keys that are not listed" do
      params_obj = described_class.new(ac_params(name: "N", extra: "no"))
      first = params_obj.permitted

      expect(first.object_id).to eq(params_obj.permitted.object_id)
      expect(first.to_unsafe_h).to eq("name" => "N")
    end
  end

  describe "#image_upload" do
    it "returns permitted[:image]" do
      tempfile = Tempfile.new([ "sauce", ".png" ])
      tempfile.write("x")
      tempfile.rewind
      upload = Rack::Test::UploadedFile.new(tempfile.path, "image/png")

      params_obj = described_class.new(ac_params(image: upload))

      expect(params_obj.image_upload).to eq(params_obj.permitted[:image])
    ensure
      tempfile.close!
    end

    it "returns nil when image is not in permitted params" do
      params_obj = described_class.new(ac_params(name: "Only"))

      expect(params_obj.image_upload).to be_nil
    end
  end
end
