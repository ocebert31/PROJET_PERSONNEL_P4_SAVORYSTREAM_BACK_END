# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocaleHints::AcceptLanguageNegotiator do
  describe ".call" do
    it "defaults to french when header is absent" do
      result = described_class.call(nil)

      expect(result.language).to eq("fr")
      expect(result.locale_tag).to eq("fr-FR")
      expect(result.language_source).to eq(described_class::SOURCE_DEFAULT)
      expect(result).not_to be_from_header
    end

    it "defaults to french when header is blank" do
      result = described_class.call("   ")

      expect(result.language_source).to eq(described_class::SOURCE_DEFAULT)
      expect(result).not_to be_from_header
    end

    it "selects french from fr-FR with quality 1" do
      result = described_class.call("fr-FR,en;q=0.8")

      expect(result.language).to eq("fr")
      expect(result.locale_tag).to eq("fr-FR")
      expect(result.language_source).to eq(described_class::SOURCE_ACCEPT_LANGUAGE)
      expect(result).to be_from_header
    end

    it "prefers highest q even when english appears earlier in the raw string order" do
      result = described_class.call("en;q=0.9,fr-FR;q=1.0")

      expect(result.language).to eq("fr")
      expect(result.locale_tag).to eq("fr-FR")
      expect(result).to be_from_header
    end

    it "formats en-US casing for locale_tag from en-us" do
      result = described_class.call("en-us")

      expect(result.language).to eq("en")
      expect(result.locale_tag).to eq("en-US")
      expect(result).to be_from_header
    end

    it "formats fr-CA and keeps french as primary language" do
      result = described_class.call("fr-CA,en;q=0.5")

      expect(result.language).to eq("fr")
      expect(result.locale_tag).to eq("fr-CA")
      expect(result).to be_from_header
    end

    it "returns language-only tag without inventing a default region" do
      result = described_class.call("fr,en;q=0.5")

      expect(result.language).to eq("fr")
      expect(result.locale_tag).to eq("fr")
      expect(result).to be_from_header
    end

    it "ignores unsupported german and falls through to french when present lower in list" do
      result = described_class.call("de-DE,fr;q=0.8")

      expect(result.language).to eq("fr")
      expect(result.language_source).to eq(described_class::SOURCE_ACCEPT_LANGUAGE)
      expect(result).to be_from_header
    end

    it "defaults when only unsupported locales are advertised" do
      result = described_class.call("de-DE,es-ES;q=0.9")

      expect(result.language).to eq("fr")
      expect(result.language_source).to eq(described_class::SOURCE_DEFAULT)
      expect(result).not_to be_from_header
    end

    it "defaults when header is only a wildcard" do
      result = described_class.call("*")

      expect(result.language_source).to eq(described_class::SOURCE_DEFAULT)
      expect(result).not_to be_from_header
    end

    it "treats invalid q values as 1.0 and still negotiates supported language" do
      result = described_class.call("en;q=invalid")

      expect(result.language).to eq("en")
      expect(result.locale_tag).to eq("en")
      expect(result).to be_from_header
    end

    it "selects first supported language when two entries share the same q" do
      result = described_class.call("en;q=1.0,fr-FR;q=1.0")

      expect(result.language).to eq("en")
      expect(result.locale_tag).to eq("en")
      expect(result).to be_from_header
    end
  end

  describe LocaleHints::AcceptLanguageNegotiator::Result do
    describe "#from_header?" do
      it "is true when language_source is accept_language" do
        result = described_class.new(
          language: "en",
          locale_tag: "en-US",
          language_source: LocaleHints::AcceptLanguageNegotiator::SOURCE_ACCEPT_LANGUAGE
        )

        expect(result).to be_from_header
      end

      it "is false when language_source is default" do
        result = described_class.new(
          language: "fr",
          locale_tag: "fr-FR",
          language_source: LocaleHints::AcceptLanguageNegotiator::SOURCE_DEFAULT
        )

        expect(result).not_to be_from_header
      end
    end
  end
end
