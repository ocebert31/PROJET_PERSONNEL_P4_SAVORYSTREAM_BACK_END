# frozen_string_literal: true

require "rails_helper"
require "rack/test"

RSpec.describe Api::V1::Sauces::SauceCreateRequiredValidator do
  def build_permitted(hash)
    ActionController::Parameters.new(hash).permit(
      :name, :tagline, :description, :characteristic, :is_available, :category_id,
      :isAvailable, :categoryId, :image,
      stock: [ :quantity ],
      conditionings: [ :volume, :price ],
      ingredients: [ :name, :quantity ]
    )
  end

  it "returns no errors when create payload is complete" do
    tempfile = Tempfile.new([ "sauce", ".png" ])
    tempfile.write("x")
    tempfile.rewind
    upload = Rack::Test::UploadedFile.new(tempfile.path, "image/png")

    permitted = build_permitted(
      name: "Sriracha",
      tagline: "Hot",
      description: "Desc",
      characteristic: "Carac",
      is_available: true,
      category_id: "uuid-1",
      image: upload,
      stock: { quantity: 10 },
      conditionings: [ { volume: "250ml", price: "6.90" } ],
      ingredients: [ { name: "Piment", quantity: "30%" } ]
    )

    errors = described_class.new(permitted: permitted, image_upload: permitted[:image]).errors
    expect(errors).to eq({})
  ensure
    tempfile.close!
  end

  it "returns required errors for missing fields" do
    permitted = build_permitted(name: "Only Name")

    errors = described_class.new(permitted: permitted, image_upload: nil).errors
    expect(errors[:tagline]).to be_present
    expect(errors[:description]).to be_present
    expect(errors[:characteristic]).to be_present
    expect(errors[:category_id]).to be_present
    expect(errors[:is_available]).to be_present
    expect(errors[:image]).to be_present
    expect(errors[:stock]).to be_present
    expect(errors[:conditionings]).to be_present
    expect(errors[:ingredients]).to be_present
  end
end
