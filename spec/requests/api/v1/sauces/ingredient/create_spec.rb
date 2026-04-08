# frozen_string_literal: true

require "rails_helper"
require_relative "ingredient_request_setup"

RSpec.describe "Api::V1::Sauces::Ingredient::CreateController", type: :request do
  include_context "API V1 sauces ingredient request setup"

  describe "POST /api/v1/sauces/ingredients" do
    context "when authenticated as admin" do
      it "creates an ingredient and returns 201 with payload and message" do
        post api_v1_ingredients_url,
             params: { name: "Vinaigre", quantity: "5%", sauce_id: sauce.id }.to_json,
             headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:created)
        expect(response_json["message"]).to eq("Ingrédient créé.")
        expect(response_json["ingredient"]["name"]).to eq("Vinaigre")
        expect(response_json["ingredient"]["sauce_id"]).to eq(sauce.id)
      end

      it "returns unprocessable entity with errors when the record cannot be saved" do
        post api_v1_ingredients_url,
             params: { name: "", quantity: "5%", sauce_id: sauce.id }.to_json,
             headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to be_a(Hash)
        expect(response_json["errors"]).to be_present
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        post api_v1_ingredients_url,
             params: { name: "X", quantity: "1%", sauce_id: sauce.id }.to_json,
             headers: customer_headers.merge(json_headers)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        post api_v1_ingredients_url,
             params: { name: "X", quantity: "1%", sauce_id: sauce.id }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
