# frozen_string_literal: true

require "rails_helper"
require_relative "sauce_request_setup"

RSpec.describe "Api::V1::Sauces::IndexController", type: :request do
  include_context "API V1 sauces resource request setup"

  describe "GET /api/v1/sauces" do
    context "when authenticated as admin" do
      it "returns sauces ordered by name ascending" do
        Sauce.create!(name: "Zebra Sauce", tagline: "Z.", category: category, is_available: true)
        Sauce.create!(name: "Alpha Sauce", tagline: "A.", category: category, is_available: true)

        get api_v1_sauces_url, headers: admin_headers

        expect(response).to have_http_status(:ok)
        names = response_json["sauces"].map { |s| s["name"] }
        expect(names).to eq([ "Alpha Sauce", "Zebra Sauce" ])
      end

      it "returns an empty list when there are no sauces" do
        get api_v1_sauces_url, headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["sauces"]).to eq([])
      end

      it "includes image_url for each sauce (nil, stored URL, or Active Storage)" do
        plain = Sauce.create!(name: "Plain Sauce", tagline: "Sans image.", category: category, is_available: true)
        external = Sauce.create!(
          name: "External Sauce",
          tagline: "URL colonne.",
          category: category,
          is_available: true,
          image_url: "https://cdn.example.com/x.png"
        )
        uploaded = Sauce.create!(name: "Uploaded Sauce", tagline: "Fichier.", category: category, is_available: true)
        uploaded.image.attach(fixture_file_upload(Rails.root.join("spec/fixtures/files/one_pixel.png"), "image/png"))

        get api_v1_sauces_url, headers: admin_headers

        expect(response).to have_http_status(:ok)
        by_name = response_json["sauces"].index_by { |s| s["name"] }

        expect(by_name["Plain Sauce"]["image_url"]).to be_nil
        expect(by_name["External Sauce"]["image_url"]).to eq("https://cdn.example.com/x.png")
        expect(by_name["Uploaded Sauce"]["image_url"]).to be_present
        expect(by_name["Uploaded Sauce"]["image_url"]).to include("rails/active_storage")
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        get api_v1_sauces_url

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        get api_v1_sauces_url, headers: customer_headers

        expect(response).to have_http_status(:forbidden)
        expect(response_json["message"]).to include("administrateurs")
      end
    end
  end
end
