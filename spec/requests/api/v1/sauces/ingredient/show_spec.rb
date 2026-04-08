# frozen_string_literal: true

require "rails_helper"
require_relative "ingredient_request_setup"

RSpec.describe "Api::V1::Sauces::Ingredient::ShowController", type: :request do
  include_context "API V1 sauces ingredient request setup"

  describe "GET /api/v1/sauces/ingredients/:id" do
    context "when authenticated as admin" do
      it "returns the ingredient payload" do
        ingredient = Ingredient.create!(sauce: sauce, name: "Ail", quantity: "10%")

        get api_v1_ingredient_url(ingredient.id), headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["ingredient"]["id"]).to eq(ingredient.id)
        expect(response_json["ingredient"]["name"]).to eq("Ail")
        expect(response_json["ingredient"]["sauce_id"]).to eq(sauce.id)
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000001"

        get api_v1_ingredient_url(unknown_id), headers: admin_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        ingredient = Ingredient.create!(sauce: sauce, name: "Solo", quantity: "1%")

        get api_v1_ingredient_url(ingredient.id)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        ingredient = Ingredient.create!(sauce: sauce, name: "Client", quantity: "1%")

        get api_v1_ingredient_url(ingredient.id), headers: customer_headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
