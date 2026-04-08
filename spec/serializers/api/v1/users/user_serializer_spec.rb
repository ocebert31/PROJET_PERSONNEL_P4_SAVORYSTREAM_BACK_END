# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Users::UserSerializer do
  describe ".call" do
    it "returns the nominal payload for a user" do
      user = create(:user, first_name: "Jean", last_name: "Dupont", email: "jean@example.com", phone_number: "0612345678")

      json = described_class.call(user)

      expect(json).to eq(
        id: user.id,
        first_name: "Jean",
        last_name: "Dupont",
        email: "jean@example.com",
        phone_number: "0612345678",
        role: "customer",
        created_at: user.created_at,
        updated_at: user.updated_at
      )
    end
  end
end
