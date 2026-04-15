# frozen_string_literal: true

require "rails_helper"
require_relative "sauce_request_setup"

RSpec.describe "Api::V1::Sauces::CreateController", type: :request do
  include_context "API V1 sauces resource request setup"

  describe "POST /api/v1/sauces" do
    context "when authenticated as admin" do
      it "creates a sauce with nested stock, conditionings, and ingredients" do
        file = fixture_file_upload(Rails.root.join("spec/fixtures/files/one_pixel.png"), "image/png")

        post api_v1_sauces_url,
             params: {
               name: "Sriracha Create Spec",
               tagline: "Pimente tout.",
               description: "Une sauce relevée et équilibrée.",
               characteristic: "Piquante",
               is_available: true,
               category_id: category.id,
               image: file,
               stock: { quantity: 12 },
               conditionings: [ { volume: "250ml", price: "6.90" } ],
               ingredients: [ { name: "Piment", quantity: "30%" } ]
             },
             headers: admin_headers

        expect(response).to have_http_status(:created)
        expect(response_json["message"]).to eq("Sauce créée.")
        expect(response_json["sauce"]["name"]).to eq("Sriracha Create Spec")
        expect(response_json["sauce"]["stock"]["quantity"]).to eq(12)
        expect(response_json["sauce"]["conditionings"].first["volume"]).to eq("250ml")
        expect(response_json["sauce"]["ingredients"].first["name"]).to eq("Piment")
      end

      it "creates a sauce with an uploaded image (multipart)" do
        file = fixture_file_upload(Rails.root.join("spec/fixtures/files/one_pixel.png"), "image/png")

        post api_v1_sauces_url,
             params: {
               name: "SauceImage Create Spec",
               tagline: "Avec image.",
               description: "Description obligatoire.",
               characteristic: "Caracteristique obligatoire.",
               category_id: category.id,
               is_available: true,
               stock: { quantity: 8 },
               conditionings: [ { volume: "150ml", price: "4.50" } ],
               ingredients: [ { name: "Ail", quantity: "5%" } ],
               image: file
             },
             headers: admin_headers

        expect(response).to have_http_status(:created)
        expect(response_json["message"]).to eq("Sauce créée.")
        expect(response_json["sauce"]["image_url"]).to be_present
        expect(response_json["sauce"]["image_url"]).to include("rails/active_storage")
      end

      it "returns unprocessable entity with required field errors when payload is incomplete" do
        post api_v1_sauces_url,
             params: { name: "Incomplete" }.to_json,
             headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to be_a(Hash)
        expect(response_json["errors"]["tagline"]).to be_present
        expect(response_json["errors"]["description"]).to be_present
        expect(response_json["errors"]["characteristic"]).to be_present
        expect(response_json["errors"]["category_id"]).to be_present
        expect(response_json["errors"]["is_available"]).to be_present
        expect(response_json["errors"]["image"]).to be_present
        expect(response_json["errors"]["stock"]).to be_present
        expect(response_json["errors"]["conditionings"]).to be_present
        expect(response_json["errors"]["ingredients"]).to be_present
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        post api_v1_sauces_url,
             params: { name: "X" }.to_json,
             headers: customer_headers.merge(json_headers)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        post api_v1_sauces_url,
             params: { name: "X" }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
