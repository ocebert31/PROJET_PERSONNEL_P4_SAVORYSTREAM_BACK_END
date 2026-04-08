# frozen_string_literal: true

require "rails_helper"
require_relative "category_request_setup"

RSpec.describe "Api::V1::Sauces::Category::UpdateController", type: :request do
  include_context "API V1 sauces category request setup"

  describe "PATCH /api/v1/sauces/categories/:id" do
    context "when authenticated as admin" do
      it "updates the category and returns 200 with payload and message" do
        category = Category.create!(name: "Piquantes")

        patch api_v1_category_url(category.id),
              params: { name: "Très piquantes" }.to_json,
              headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:ok)
        expect(response_json["message"]).to eq("Catégorie mise à jour.")
        expect(response_json["category"]["name"]).to eq("Très piquantes")
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000002"

        patch api_v1_category_url(unknown_id),
              params: { name: "Nope" }.to_json,
              headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        category = Category.create!(name: "NoEdit")

        patch api_v1_category_url(category.id),
              params: { name: "X" }.to_json,
              headers: customer_headers.merge(json_headers)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        category = Category.create!(name: "NoToken")

        patch api_v1_category_url(category.id),
              params: { name: "X" }.to_json,
              headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
