# frozen_string_literal: true

module Api
  module V1
    module Users
      # Valide qu’un seul identifiant (email ou téléphone) est fourni pour le login.
      class SessionIdentification
        def initialize(params)
          @email = params[:email].presence&.strip&.downcase
          phone = params[:phone_number].presence || params[:phoneNumber].presence
          @phone = phone&.strip&.gsub(/\s+/, "")
        end

        attr_reader :email, :phone

        def valid?
          !invalid?
        end

        def invalid?
          both_present? || none_present?
        end

        def errors_hash
          if both_present?
            { base: [ "Fournir uniquement un email ou un numéro de téléphone, pas les deux." ] }
          elsif none_present?
            { base: [ "Email ou numéro de téléphone requis." ] }
          else
            {}
          end
        end

        private

        def both_present?
          @email.present? && @phone.present?
        end

        def none_present?
          @email.blank? && @phone.blank?
        end
      end
    end
  end
end
