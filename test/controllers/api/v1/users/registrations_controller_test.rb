# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Users
      class RegistrationsControllerTest < ActionDispatch::IntegrationTest
        setup { User.delete_all }

        # Successful registration

        test "successful registration creates a user and returns a success message and safe user payload" do
          assert_difference -> { User.count }, 1 do
            submit_registration(valid_registration_payload)
          end

          assert_response :created
          payload = response_json

          assert_equal "Inscription réussie.", payload["message"]
          assert_equal "jane@example.com", payload["user"]["email"]
          assert_equal "customer", payload["user"]["role"]
          assert_nil payload["user"]["password_digest"]
        end

        test "successful registration always persists customer role when the client sends another role value" do
          payload = valid_registration_payload.merge(
            email: "bob@example.com",
            phone_number: "0698765432",
            role: "admin"
          )

          assert_difference -> { User.count }, 1 do
            submit_registration(payload)
          end

          assert_response :created
          assert_equal "customer", User.find_by!(email: "bob@example.com").role
        end

        # Registration failures

        test "registration fails when attributes fail model validation and returns error details" do
          assert_no_difference -> { User.count } do
            submit_registration(invalid_registration_payload)
          end

          assert_response :unprocessable_entity
          assert_predicate response_json["errors"], :present?
        end

        private

        def submit_registration(registration_params)
          post api_v1_users_registrations_url, params: registration_params, as: :json
        end

        def response_json
          JSON.parse(response.body)
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
    end
  end
end
