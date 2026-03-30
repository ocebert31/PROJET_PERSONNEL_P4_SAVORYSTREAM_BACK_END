# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionIdentification do
  describe "valid" do
    context "nominal: email only" do
      it "is valid" do
        identification = described_class.new(email: "jane@example.com")

        expect(identification).to be_valid
      end
    end

    context "nominal: phone_number only" do
      it "is valid" do
        identification = described_class.new(phone_number: "0612345678")

        expect(identification).to be_valid
        expect(identification.phone).to eq("0612345678")
      end
    end

    context "when email has mixed case and surrounding spaces" do
      it "normalizes email and stays valid" do
        identification = described_class.new(email: "  Jane@EXAMPLE.COM  ")

        expect(identification.email).to eq("jane@example.com")
        expect(identification).to be_valid
      end
    end

    context "when phone has spaces" do
      it "strips spaces and stays valid" do
        identification = described_class.new(phone_number: " 06 12 34 56 78 ")

        expect(identification.phone).to eq("0612345678")
        expect(identification).to be_valid
      end
    end
  end

  describe "invalid?" do
    context "when both email and phone are present" do
      it "is invalid" do
        identification = described_class.new(
          email: "jane@example.com",
          phone_number: "0612345678"
        )

        expect(identification.invalid?).to be true
      end
    end

    context "when neither email nor phone is present" do
      it "is invalid" do
        identification = described_class.new({})

        expect(identification.invalid?).to be true
      end

      it "is invalid when only unrelated keys are present" do
        identification = described_class.new(password: "secret")

        expect(identification.invalid?).to be true
      end
    end
  end

  describe "errors_hash" do
    context "when identification is valid" do
      it "returns an empty hash" do
        identification = described_class.new(email: "jane@example.com")

        expect(identification.errors_hash).to eq({})
      end
    end

    context "when both email and phone are present" do
      it "returns a base error mentioning both identifiers" do
        identification = described_class.new(
          email: "jane@example.com",
          phone_number: "0612345678"
        )

        expect(identification.errors_hash[:base].first).to include("pas les deux")
      end
    end

    context "when neither email nor phone is present" do
      it "returns a base error requiring an identifier" do
        identification = described_class.new({})

        expect(identification.errors_hash[:base].first).to include("requis")
      end
    end
  end
end
