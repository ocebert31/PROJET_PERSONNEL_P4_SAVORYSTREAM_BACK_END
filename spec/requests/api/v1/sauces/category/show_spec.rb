# frozen_string_literal: true

require "rails_helper"
require_relative "category_request_setup"

RSpec.describe "Api::V1::Sauces::Category::ShowController", type: :request do
  include_context "API V1 sauces category request setup"

  describe "GET /api/v1/sauces/categories/:id" do
    context "when authenticated as admin" do
      it "returns the category payload" do
        category = Category.create!(name: "Douces")

        get api_v1_category_url(category.id), headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["category"]["id"]).to eq(category.id)
        expect(response_json["category"]["name"]).to eq("Douces")
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000001"

        get api_v1_category_url(unknown_id), headers: admin_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        category = Category.create!(name: "Solo")

        get api_v1_category_url(category.id)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        category = Category.create!(name: "Client")

        get api_v1_category_url(category.id), headers: customer_headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
