# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Localisations::ShowController", type: :request do
  describe "GET /api/v1/localisations" do
    context "when default market FR and no Accept-Language" do
      before do
        allow(Rails.application.config.x).to receive_messages(default_market_country_alpha2: "FR")
      end

      it "returns EUR market tax and omits EUR conversion rate when currency is EUR" do
        get api_v1_localisations_url
        expect(response).to have_http_status(:ok)
        loc = response_json["localisations"]
        expect(loc["language"]).to eq("fr")
        expect(loc["locale_tag"]).to eq("fr-FR")
        expect(loc["country_alpha2"]).to eq("FR")
        expect(loc["currency"]).to eq("EUR")
        expect(loc["vat_rate"]).to eq("0.2")
        expect(loc).not_to have_key("eur_to_currency_rate")
        expect(loc["sources"]).to eq({ "country" => "default_config", "language" => "default" })
      end
    end

    context "when Accept-Language requests english" do
      before do
        allow(Rails.application.config.x).to receive_messages(default_market_country_alpha2: "FR")
      end

      it "negotiates english, infers United States market from locale region, exposes USD rate" do
        get api_v1_localisations_url, headers: { "Accept-Language" => "en-US,fr;q=0.6" }

        loc = response_json["localisations"]
        expect(loc["language"]).to eq("en")
        expect(loc["locale_tag"]).to eq("en-US")
        expect(loc["sources"]["language"]).to eq("accept_language")
        expect(loc["country_alpha2"]).to eq("US")
        expect(loc["currency"]).to eq("USD")
        expect(BigDecimal(loc["vat_rate"])).to eq(0)
        expect(loc["eur_to_currency_rate"]).to eq(BigDecimal("1.08").to_s("F"))
        expect(loc["sources"]["country"]).to eq("accept_language_region")
      end
    end

    context "when Accept-Language includes a regional francophone market" do
      before do
        allow(Rails.application.config.x).to receive_messages(default_market_country_alpha2: "FR")
      end

      it "infers CH from fr-CH overriding default FR" do
        get api_v1_localisations_url, headers: { "Accept-Language" => "fr-CH,fr;q=0.9" }

        loc = response_json["localisations"]
        expect(loc["language"]).to eq("fr")
        expect(loc["locale_tag"]).to eq("fr-CH")
        expect(loc["country_alpha2"]).to eq("CH")
        expect(loc["currency"]).to eq("CHF")
        expect(loc["vat_rate"]).to eq("0.081")
        expect(loc["sources"]["country"]).to eq("accept_language_region")
      end
    end

    context "when Accept-Language is en-GB and default FR" do
      before do
        allow(Rails.application.config.x).to receive_messages(default_market_country_alpha2: "FR")
      end

      it "infers GB from locale region despite default FR server market" do
        get api_v1_localisations_url, headers: { "Accept-Language" => "en-GB;q=1" }

        loc = response_json["localisations"]
        expect(loc["country_alpha2"]).to eq("GB")
        expect(loc["currency"]).to eq("GBP")
        expect(loc["vat_rate"]).to eq("0.2")
        expect(loc["eur_to_currency_rate"]).to eq(BigDecimal("0.87").to_s("F"))
        expect(loc["sources"]["country"]).to eq("accept_language_region")
      end
    end

    context "when default country code is absent from YAML" do
      before do
        allow(Rails.application.config.x).to receive_messages(default_market_country_alpha2: "XX")
      end

      it "falls back to FR row and emits FR country" do
        get api_v1_localisations_url
        loc = response_json["localisations"]
        expect(loc["country_alpha2"]).to eq("FR")
        expect(loc["currency"]).to eq("EUR")
      end
    end
  end
end
