# frozen_string_literal: true

module LocaleHints
  # Parse RFC 9239 / traditionnel Accept-Language et choisit une langue supportée.
  #
  # Sans header (ou langues non supportées), le repli est toujours +fr+ / +fr-FR+ :
  # ce n’est pas le pays par défaut serveur (+default_market_country_alpha2+).
  # L’inférence pays (US, CH, GB…) est faite plus tard par +DisplayMarket+ uniquement
  # quand +Result#from_header?+ est vrai et que le +locale_tag+ porte une région connue.
  class AcceptLanguageNegotiator
    SUPPORTED_LANGUAGE_CODES = %w[fr en].freeze

    SOURCE_ACCEPT_LANGUAGE = "accept_language"
    SOURCE_DEFAULT = "default"

    DEFAULT_LANGUAGE = "fr"
    DEFAULT_LOCALE_TAG = "fr-FR"

    Result = Struct.new(:language, :locale_tag, :language_source, keyword_init: true) do
      def from_header?
        language_source == AcceptLanguageNegotiator::SOURCE_ACCEPT_LANGUAGE
      end
    end

    class << self
      # @param accept_language_header [String, nil] valeur brute du header Accept-Language
      # @return [Result]
      def call(accept_language_header)
        header = accept_language_header.to_s.strip

        return default_result if header.blank?

        candidates = ranked_language_tags(header)
        candidates.each do |entry|
          canonical = entry[:canonical]
          primary = extract_primary_language(canonical)
          next unless primary && SUPPORTED_LANGUAGE_CODES.include?(primary)

          return Result.new(
            language: primary,
            locale_tag: format_locale_tag(entry[:raw_tag]),
            language_source: SOURCE_ACCEPT_LANGUAGE
          )
        end

        default_result
      end

      private

      def default_result
        Result.new(
          language: DEFAULT_LANGUAGE,
          locale_tag: DEFAULT_LOCALE_TAG,
          language_source: SOURCE_DEFAULT
        )
      end

      def ranked_language_tags(header)
        header.split(",").filter_map do |segment|
          part = segment.strip
          next if part.blank?

          lang_part, _sep, attrs = part.partition(";")
          raw_tag = lang_part.gsub(/\s+/, "")
          canonical = raw_tag.downcase.tr("_", "-")
          next if canonical.blank? || canonical == "*"

          q = parse_quality(attrs)
          { canonical:, raw_tag:, q: }
        end.sort_by { |row| -row[:q].to_f }
      end

      def parse_quality(attrs_fragment)
        return 1.0 if attrs_fragment.blank?

        attrs_fragment.split(";").each do |fragment|
          k, _eq, v = fragment.strip.partition("=")
          next unless k.casecmp("q").zero?

          parsed = Float(v, exception: false)
          return parsed if parsed&.between?(0, 1)
        end

        1.0
      end

      def extract_primary_language(canonical_tag)
        canonical_tag&.split("-", 2)&.first&.presence
      end

      # Forme compatible i18next usuelle : langue en minuscule, région alpha-2 en majuscules.
      def format_locale_tag(raw_tag)
        segments = raw_tag.to_s.tr("_", "-").split("-").reject(&:blank?)
        return DEFAULT_LOCALE_TAG if segments.empty?

        first = segments[0].downcase
        tail = segments[1..].map do |segment|
          segment.match?(/\A[A-Za-z]{2}\z/) ? segment.upcase : segment.downcase
        end

        ([ first ] + tail).join("-")
      end
    end
  end
end
