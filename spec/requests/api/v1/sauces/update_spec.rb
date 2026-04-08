# frozen_string_literal: true

require "rails_helper"
require_relative "sauce_request_setup"

RSpec.describe "Api::V1::Sauces::UpdateController", type: :request do
  include_context "API V1 sauces resource request setup"

  describe "PATCH /api/v1/sauces/:id" do
    context "when authenticated as admin" do
      it "updates the sauce and returns 200 with payload and message" do
        sauce = Sauce.create!(name: "Sriracha Update Spec", tagline: "Pimente tout.", category: category, is_available: true)

        patch api_v1_sauce_url(sauce.id),
              params: { tagline: "Encore plus piquante." }.to_json,
              headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:ok)
        expect(response_json["message"]).to eq("Sauce mise à jour.")
        expect(response_json["sauce"]["tagline"]).to eq("Encore plus piquante.")
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000002"

        patch api_v1_sauce_url(unknown_id),
              params: { tagline: "Nope" }.to_json,
              headers: admin_headers.merge(json_headers)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        sauce = Sauce.create!(name: "NoEdit Sauce", tagline: "X.", category: category, is_available: true)

        patch api_v1_sauce_url(sauce.id),
              params: { tagline: "Y" }.to_json,
              headers: customer_headers.merge(json_headers)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        sauce = Sauce.create!(name: "NoToken Sauce", tagline: "X.", category: category, is_available: true)

        patch api_v1_sauce_url(sauce.id),
              params: { tagline: "Y" }.to_json,
              headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
