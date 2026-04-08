# frozen_string_literal: true

require "rails_helper"
require_relative "category_request_setup"

RSpec.describe "Api::V1::Sauces::Category::IndexController", type: :request do
  include_context "API V1 sauces category request setup"

  describe "GET /api/v1/sauces/categories" do
    context "when authenticated as admin" do
      it "returns categories ordered by name" do
        Category.create!(name: "Zebra")
        Category.create!(name: "Alpha")

        get api_v1_categories_url, headers: admin_headers

        expect(response).to have_http_status(:ok)
        names = response_json["categories"].map { |c| c["name"] }
        expect(names).to eq(%w[Alpha Zebra])
      end

      it "returns an empty list when there are no categories" do
        get api_v1_categories_url, headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["categories"]).to eq([])
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        get api_v1_categories_url

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        get api_v1_categories_url, headers: customer_headers

        expect(response).to have_http_status(:forbidden)
        expect(response_json["message"]).to include("administrateurs")
      end
    end
  end
end
