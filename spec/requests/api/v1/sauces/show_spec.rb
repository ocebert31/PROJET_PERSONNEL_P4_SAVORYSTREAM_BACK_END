# frozen_string_literal: true

require "rails_helper"
require_relative "sauce_request_setup"

RSpec.describe "Api::V1::Sauces::ShowController", type: :request do
  include_context "API V1 sauces resource request setup"

  describe "GET /api/v1/sauces/:id" do
    context "without authentication" do
      it "returns the sauce payload" do
        sauce = Sauce.create!(name: "Sriracha Show", tagline: "Pimente tout.", category: category, is_available: true)

        get api_v1_sauce_url(sauce.id)

        expect(response).to have_http_status(:ok)
        expect(response_json["sauce"]["id"]).to eq(sauce.id)
        expect(response_json["sauce"]["tagline"]).to eq("Pimente tout.")
        expect(response_json["sauce"]["category"]["id"]).to eq(category.id)
        expect(response_json["sauce"]["image_url"]).to be_nil
      end

      it "returns an Active Storage image_url when an image is attached" do
        sauce = Sauce.create!(name: "Sriracha Show Image", tagline: "Avec photo.", category: category, is_available: true)
        file = fixture_file_upload(Rails.root.join("spec/fixtures/files/one_pixel.png"), "image/png")
        sauce.image.attach(file)

        get api_v1_sauce_url(sauce.id)

        expect(response).to have_http_status(:ok)
        url = response_json["sauce"]["image_url"]
        expect(url).to be_present
        expect(url).to include("rails/active_storage")
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000001"

        get api_v1_sauce_url(unknown_id)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as customer" do
      it "returns the sauce payload" do
        sauce = Sauce.create!(name: "Client Sauce", tagline: "C.", category: category, is_available: true)

        get api_v1_sauce_url(sauce.id), headers: customer_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["sauce"]["id"]).to eq(sauce.id)
      end
    end

    context "when authenticated as admin" do
      it "returns the sauce payload" do
        sauce = Sauce.create!(name: "Admin View Sauce", tagline: "A.", category: category, is_available: true)

        get api_v1_sauce_url(sauce.id), headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["sauce"]["id"]).to eq(sauce.id)
      end
    end
  end
end
