# frozen_string_literal: true

require "rails_helper"
require_relative "conditioning_request_setup"

RSpec.describe "Api::V1::Sauces::Conditioning::UpdateController", type: :request do
  include_context "API V1 sauces conditioning request setup"

  describe "PATCH /api/v1/sauces/conditionings/:id" do
    context "when authenticated as admin" do
      it "updates the conditioning and returns 200 with payload and message" do
        conditioning = Conditioning.create!(sauce: sauce, volume: "250ml", price: 6.90)

        patch api_v1_conditioning_url(conditioning.id),
              params: { volume: "330ml", price: "7.90" }.to_json,
              headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:ok)
        expect(response_json["message"]).to eq("Conditionnement mis à jour.")
        expect(response_json["conditioning"]["volume"]).to eq("330ml")
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000002"

        patch api_v1_conditioning_url(unknown_id),
              params: { volume: "330ml", price: "7.90" }.to_json,
              headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        conditioning = Conditioning.create!(sauce: sauce, volume: "250ml", price: 6.90)

        patch api_v1_conditioning_url(conditioning.id),
              params: { volume: "330ml", price: "7.90" }.to_json,
              headers: customer_headers.merge(json_headers)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        conditioning = Conditioning.create!(sauce: sauce, volume: "250ml", price: 6.90)

        patch api_v1_conditioning_url(conditioning.id),
              params: { volume: "330ml", price: "7.90" }.to_json,
              headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
