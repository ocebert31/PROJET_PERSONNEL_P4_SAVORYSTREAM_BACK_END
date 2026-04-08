# frozen_string_literal: true

require "rails_helper"
require_relative "conditioning_request_setup"

RSpec.describe "Api::V1::Sauces::Conditioning::ShowController", type: :request do
  include_context "API V1 sauces conditioning request setup"

  describe "GET /api/v1/sauces/conditionings/:id" do
    context "when authenticated as admin" do
      it "returns the conditioning payload" do
        conditioning = Conditioning.create!(sauce: sauce, volume: "500ml", price: 9.90)

        get api_v1_conditioning_url(conditioning.id), headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["conditioning"]["id"]).to eq(conditioning.id)
        expect(response_json["conditioning"]["volume"]).to eq("500ml")
        expect(response_json["conditioning"]["sauce_id"]).to eq(sauce.id)
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000001"

        get api_v1_conditioning_url(unknown_id), headers: admin_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        conditioning = Conditioning.create!(sauce: sauce, volume: "250ml", price: 1.00)

        get api_v1_conditioning_url(conditioning.id)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        conditioning = Conditioning.create!(sauce: sauce, volume: "250ml", price: 1.00)

        get api_v1_conditioning_url(conditioning.id), headers: customer_headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
