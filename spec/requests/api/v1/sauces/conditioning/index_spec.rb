# frozen_string_literal: true

require "rails_helper"
require_relative "conditioning_request_setup"

RSpec.describe "Api::V1::Sauces::Conditioning::IndexController", type: :request do
  include_context "API V1 sauces conditioning request setup"

  describe "GET /api/v1/sauces/conditionings" do
    context "when authenticated as admin" do
      it "returns conditionings ordered by created_at ascending" do
        first = Conditioning.create!(sauce: sauce, volume: "100ml", price: 3.00)
        second = Conditioning.create!(sauce: sauce, volume: "200ml", price: 4.00)

        get api_v1_conditionings_url, headers: admin_headers

        expect(response).to have_http_status(:ok)
        ids = response_json["conditionings"].map { |c| c["id"] }
        expect(ids).to eq([ first.id, second.id ])
      end

      it "returns an empty list when there are no conditionings" do
        get api_v1_conditionings_url, headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response_json["conditionings"]).to eq([])
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        get api_v1_conditionings_url

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        get api_v1_conditionings_url, headers: customer_headers

        expect(response).to have_http_status(:forbidden)
        expect(response_json["message"]).to include("administrateurs")
      end
    end
  end
end
