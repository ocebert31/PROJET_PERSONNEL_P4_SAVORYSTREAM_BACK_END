# frozen_string_literal: true

require "rails_helper"
require_relative "conditioning_request_setup"

RSpec.describe "Api::V1::Sauces::Conditioning::CreateController", type: :request do
  include_context "API V1 sauces conditioning request setup"

  describe "POST /api/v1/sauces/conditionings" do
    context "when authenticated as admin" do
      it "creates a conditioning and returns 201 with payload and message" do
        post api_v1_conditionings_url,
             params: { volume: "750ml", price: "12.50", sauce_id: sauce.id }.to_json,
             headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:created)
        expect(response_json["message"]).to eq("Conditionnement créé.")
        expect(response_json["conditioning"]["volume"]).to eq("750ml")
        expect(response_json["conditioning"]["sauce_id"]).to eq(sauce.id)
      end

      it "returns unprocessable entity with errors when the record cannot be saved" do
        post api_v1_conditionings_url,
             params: { volume: "", price: "1.00", sauce_id: sauce.id }.to_json,
             headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to be_a(Hash)
        expect(response_json["errors"]).to be_present
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        post api_v1_conditionings_url,
             params: { volume: "750ml", price: "12.50", sauce_id: sauce.id }.to_json,
             headers: customer_headers.merge(json_headers)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        post api_v1_conditionings_url,
             params: { volume: "750ml", price: "12.50", sauce_id: sauce.id }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
