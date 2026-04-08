# frozen_string_literal: true

require "rails_helper"
require_relative "conditioning_request_setup"

RSpec.describe "Api::V1::Sauces::Conditioning::DestroyController", type: :request do
  include_context "API V1 sauces conditioning request setup"

  describe "DELETE /api/v1/sauces/conditionings/:id" do
    context "when authenticated as admin" do
      it "deletes the conditioning" do
        conditioning = Conditioning.create!(sauce: sauce, volume: "250ml", price: 6.90)

        delete api_v1_conditioning_url(conditioning.id), headers: admin_headers

        expect(response).to have_http_status(:no_content)
        expect(Conditioning.find_by(id: conditioning.id)).to be_nil
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000003"

        delete api_v1_conditioning_url(unknown_id), headers: admin_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        conditioning = Conditioning.create!(sauce: sauce, volume: "250ml", price: 6.90)

        delete api_v1_conditioning_url(conditioning.id), headers: customer_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        conditioning = Conditioning.create!(sauce: sauce, volume: "250ml", price: 6.90)

        delete api_v1_conditioning_url(conditioning.id)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
