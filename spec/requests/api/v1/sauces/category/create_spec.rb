# frozen_string_literal: true

require "rails_helper"
require_relative "category_request_setup"

RSpec.describe "Api::V1::Sauces::Category::CreateController", type: :request do
  include_context "API V1 sauces category request setup"

  describe "POST /api/v1/sauces/categories" do
    context "when authenticated as admin" do
      it "creates a category and returns 201 with payload and message" do
        post api_v1_categories_url,
             params: { name: "Fumées" }.to_json,
             headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:created)
        expect(response_json["message"]).to eq("Catégorie créée.")
        expect(response_json["category"]["name"]).to eq("Fumées")
      end

      it "returns unprocessable entity with errors when the record cannot be saved" do
        post api_v1_categories_url,
             params: { name: "" }.to_json,
             headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to be_a(Hash)
        expect(response_json["errors"]).to be_present
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        post api_v1_categories_url,
             params: { name: "Acides" }.to_json,
             headers: customer_headers.merge(json_headers)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        post api_v1_categories_url,
             params: { name: "Acides" }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
