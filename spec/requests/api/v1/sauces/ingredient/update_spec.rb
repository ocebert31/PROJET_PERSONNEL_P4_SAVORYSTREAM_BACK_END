# frozen_string_literal: true

require "rails_helper"
require_relative "ingredient_request_setup"

RSpec.describe "Api::V1::Sauces::Ingredient::UpdateController", type: :request do
  include_context "API V1 sauces ingredient request setup"

  describe "PATCH /api/v1/sauces/ingredients/:id" do
    context "when authenticated as admin" do
      it "updates the ingredient and returns 200 with payload and message" do
        ingredient = Ingredient.create!(sauce: sauce, name: "Piment", quantity: "30%")

        patch api_v1_ingredient_url(ingredient.id),
              params: { quantity: "35%" }.to_json,
              headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:ok)
        expect(response_json["message"]).to eq("Ingrédient mis à jour.")
        expect(response_json["ingredient"]["quantity"]).to eq("35%")
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000002"

        patch api_v1_ingredient_url(unknown_id),
              params: { quantity: "10%" }.to_json,
              headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        ingredient = Ingredient.create!(sauce: sauce, name: "NoEdit", quantity: "1%")

        patch api_v1_ingredient_url(ingredient.id),
              params: { quantity: "2%" }.to_json,
              headers: customer_headers.merge(json_headers)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        ingredient = Ingredient.create!(sauce: sauce, name: "NoToken", quantity: "1%")

        patch api_v1_ingredient_url(ingredient.id),
              params: { quantity: "2%" }.to_json,
              headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
