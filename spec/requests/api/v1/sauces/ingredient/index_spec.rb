# frozen_string_literal: true

require "rails_helper"
require_relative "ingredient_request_setup"

RSpec.describe "Api::V1::Sauces::Ingredient::IndexController", type: :request do
  include_context "API V1 sauces ingredient request setup"

  describe "GET /api/v1/sauces/ingredients" do
    context "when authenticated as admin" do
      it "returns ingredients ordered by created_at ascending" do
        first = Ingredient.create!(sauce: sauce, name: "First", quantity: "10%")
        second = Ingredient.create!(sauce: sauce, name: "Second", quantity: "20%")

        get api_v1_ingredients_url, headers: admin_headers

        expect(response).to have_http_status(:ok)
        ids = response_json["ingredients"].map { |i| i["id"] }
        expect(ids).to eq([ first.id, second.id ])
      end

      it "returns an empty list when there are no ingredients" do
        get api_v1_ingredients_url, headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["ingredients"]).to eq([])
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        get api_v1_ingredients_url

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        get api_v1_ingredients_url, headers: customer_headers

        expect(response).to have_http_status(:forbidden)
        expect(response_json["message"]).to include("administrateurs")
      end
    end
  end
end
