# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class SauceCreateRequiredValidator
        def initialize(permitted:, image_upload:)
          @permitted = permitted
          @image_upload = image_upload
        end

        def errors
          errors = {}
          p = @permitted

          add_required_error(errors, :name, "Le nom est requis.") if blank_like?(p[:name])
          add_required_error(errors, :tagline, "L’accroche est requise.") if blank_like?(p[:tagline])
          add_required_error(errors, :description, "La description est requise.") if blank_like?(p[:description])
          add_required_error(errors, :characteristic, "La caractéristique est requise.") if blank_like?(p[:characteristic])

          category_id = p[:category_id].presence || p[:categoryId]
          add_required_error(errors, :category_id, "La catégorie est requise.") if blank_like?(category_id)

          unless p.key?(:is_available) || p.key?(:isAvailable)
            add_required_error(errors, :is_available, "La disponibilité est requise.")
          end

          add_required_error(errors, :image, "L’image est requise.") if @image_upload.blank?

          stock_quantity = p.dig(:stock, :quantity) || p.dig("stock", "quantity")
          add_required_error(errors, :stock, "Le stock (quantité) est requis.") if blank_like?(stock_quantity)

          first_conditioning = p[:conditionings]&.first
          if first_conditioning.blank?
            add_required_error(errors, :conditionings, "Un conditionnement est requis.")
          else
            add_required_error(errors, :conditionings, "Le volume du conditionnement est requis.") if blank_like?(first_conditioning[:volume])
            add_required_error(errors, :conditionings, "Le prix du conditionnement est requis.") if blank_like?(first_conditioning[:price])
          end

          first_ingredient = p[:ingredients]&.first
          if first_ingredient.blank?
            add_required_error(errors, :ingredients, "Un ingrédient est requis.")
          else
            add_required_error(errors, :ingredients, "Le nom de l’ingrédient est requis.") if blank_like?(first_ingredient[:name])
            add_required_error(errors, :ingredients, "La quantité de l’ingrédient est requise.") if blank_like?(first_ingredient[:quantity])
          end

          errors
        end

        private

        def add_required_error(errors, key, message)
          errors[key] ||= []
          errors[key] << message
        end

        def blank_like?(value)
          return true if value.nil?
          return value.strip.empty? if value.is_a?(String)
          return false if value == false
          return value.empty? if value.respond_to?(:empty?)

          false
        end
      end
    end
  end
end
