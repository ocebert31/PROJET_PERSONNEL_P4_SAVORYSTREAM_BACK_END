# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users::Registrations", type: :request do
  before { User.delete_all }

  describe "POST /api/v1/users/registrations" do
    context "when registration succeeds" do
      it "creates a user and returns a success message and safe user payload" do
        expect do
          submit_registration(valid_registration_payload)
        end.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        payload = response_json
        expect(payload["message"]).to eq("Inscription réussie.")
        expect(payload["user"]["email"]).to eq("jane@example.com")
        expect(payload["user"]["role"]).to eq("customer")
        expect(payload["user"]["password_digest"]).to be_nil
      end

      it "always persists customer role when the client sends another role value" do
        payload = valid_registration_payload.merge(
          email: "bob@example.com",
          phone_number: "0698765432",
          role: "admin"
        )

        expect { submit_registration(payload) }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(User.find_by!(email: "bob@example.com").role).to eq("customer")
      end
    end

    context "when registration fails" do
      it "returns error details when attributes fail model validation" do
        expect do
          submit_registration(invalid_registration_payload)
        end.not_to change(User, :count)

        expect(response).to have_http_status(422)
        expect(response_json["errors"]).to be_present
      end
    end
  end

  def submit_registration(registration_params)
    post api_v1_users_registrations_url, params: registration_params, as: :json
  end

  def valid_registration_payload(overrides = {})
    {
      first_name: "Jane",
      last_name: "Doe",
      email: "jane@example.com",
      password: "password12",
      password_confirmation: "password12",
      phone_number: "0612345678"
    }.merge(overrides)
  end

  def invalid_registration_payload
    valid_registration_payload.merge(
      first_name: "",
      last_name: "",
      email: "not-an-email",
      password: "short",
      password_confirmation: "short",
      phone_number: "123"
    )
  end
end
