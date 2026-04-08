# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::CategoryParameters do
  def ac_params(hash)
    ActionController::Parameters.new(hash)
  end

  describe "#permitted" do
    it "permits the category name for a typical create/update payload" do
      permitted = described_class.new(ac_params(name: "Piquantes")).permitted

      expect(permitted.to_unsafe_h).to eq("name" => "Piquantes")
    end

    it "drops keys that are not explicitly allowed" do
      permitted = described_class.new(ac_params(name: "Safe", evil: "drop-me")).permitted

      expect(permitted.to_unsafe_h).to eq("name" => "Safe")
      expect(permitted[:evil]).to be_nil
    end
  end
end
