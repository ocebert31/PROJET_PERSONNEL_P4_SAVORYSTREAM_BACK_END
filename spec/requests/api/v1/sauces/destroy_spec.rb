# frozen_string_literal: true

require "rails_helper"
require_relative "sauce_request_setup"

RSpec.describe "Api::V1::Sauces::DestroyController", type: :request do
  include_context "API V1 sauces resource request setup"

  describe "DELETE /api/v1/sauces/:id" do
    context "when authenticated as admin" do
      it "deletes the sauce" do
        sauce = Sauce.create!(name: "Sriracha Destroy Spec", tagline: "Pimente tout.", category: category, is_available: true)

        delete api_v1_sauce_url(sauce.id), headers: admin_headers

        expect(response).to have_http_status(:no_content)
        expect(Sauce.find_by(id: sauce.id)).to be_nil
      end

      it "returns not found for an unknown id" do
        unknown_id = "00000000-0000-0000-0000-000000000003"

        delete api_v1_sauce_url(unknown_id), headers: admin_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as customer" do
      it "returns forbidden" do
        sauce = Sauce.create!(name: "NoDelete Sauce", tagline: "X.", category: category, is_available: true)

        delete api_v1_sauce_url(sauce.id), headers: customer_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the access token is missing" do
      it "returns unauthorized" do
        sauce = Sauce.create!(name: "NoTokenDel Sauce", tagline: "X.", category: category, is_available: true)

        delete api_v1_sauce_url(sauce.id)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
