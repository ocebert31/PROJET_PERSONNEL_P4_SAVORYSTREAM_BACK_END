# frozen_string_literal: true

require "rails_helper"
require_relative "category_request_setup"

RSpec.describe "Api::V1::Sauces::Category::DestroyController", type: :request do
  include_context "API V1 sauces category request setup"

  describe "DELETE /api/v1/sauces/categories/:id" do
    context "when authenticated as admin" do
      it "deletes a category that is not used by any sauce" do
        category = Category.create!(name: "Sucrées")

        delete api_v1_category_url(category.id), headers: admin_headers

        expect(response).to have_http_status(:no_content)
        expect(Category.find_by(id: category.id)).to be_nil
      end

      it "returns unprocessable entity when the category is used by a sauce" do
        category = Category.create!(name: "Utilisée")
        Sauce.create!(name: "Sriracha Test", tagline: "Tag", category: category, is_available: true)

        delete api_v1_category_url(category.id), headers: admin_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["message"]).to include("Impossible de supprimer")
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000003"

        delete api_v1_category_url(unknown_id), headers: admin_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        category = Category.create!(name: "NoDelete")

        delete api_v1_category_url(category.id), headers: customer_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        category = Category.create!(name: "NoTokenDel")

        delete api_v1_category_url(category.id)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
