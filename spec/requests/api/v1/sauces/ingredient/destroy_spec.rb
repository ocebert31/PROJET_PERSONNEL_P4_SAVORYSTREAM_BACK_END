# frozen_string_literal: true

require "rails_helper"
require_relative "ingredient_request_setup"

RSpec.describe "Api::V1::Sauces::Ingredient::DestroyController", type: :request do
  include_context "API V1 sauces ingredient request setup"

  describe "DELETE /api/v1/sauces/ingredients/:id" do
    context "when authenticated as admin" do
      it "deletes the ingredient" do
        ingredient = Ingredient.create!(sauce: sauce, name: "Piment", quantity: "30%")

        delete api_v1_ingredient_url(ingredient.id), headers: admin_headers

        expect(response).to have_http_status(:no_content)
        expect(Ingredient.find_by(id: ingredient.id)).to be_nil
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000003"

        delete api_v1_ingredient_url(unknown_id), headers: admin_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        ingredient = Ingredient.create!(sauce: sauce, name: "NoDelete", quantity: "1%")

        delete api_v1_ingredient_url(ingredient.id), headers: customer_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        ingredient = Ingredient.create!(sauce: sauce, name: "NoTokenDel", quantity: "1%")

        delete api_v1_ingredient_url(ingredient.id)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
