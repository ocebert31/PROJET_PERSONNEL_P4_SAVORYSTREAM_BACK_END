# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocaleHints::Composer do
  describe ".call" do
    it "uses default country only when Accept-Language absent (no region inference from synthetic fr-FR)" do
      allow(Rails.application.config.x).to receive_messages(default_market_country_alpha2: "DE")

      out = described_class.call(accept_language_header: nil, default_country_alpha2: "DE")

      hints = out.fetch(:localisations)
      expect(hints[:country_alpha2]).to eq("DE")
      expect(hints[:currency]).to eq("EUR")
      expect(hints[:sources][:country]).to eq("default_config")
    end

    it "infers country from region tag when language comes from header" do
      out = described_class.call(
        accept_language_header: "en-CA;q=1",
        default_country_alpha2: "FR"
      )

      hints = out.fetch(:localisations)
      expect(hints[:country_alpha2]).to eq("CA")
      expect(hints[:currency]).to eq("CAD")
      expect(hints[:sources][:country]).to eq("accept_language_region")
    end

    it "does not infer unknown alpha-2 segments and keeps default" do
      out = described_class.call(
        accept_language_header: "en-XX;q=1",
        default_country_alpha2: "FR"
      )

      hints = out.fetch(:localisations)
      expect(hints[:country_alpha2]).to eq("FR")
      expect(hints[:sources][:country]).to eq("default_config")
    end
  end
end
