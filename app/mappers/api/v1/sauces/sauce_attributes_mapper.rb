# frozen_string_literal: true

module Api
  module V1
    module Sauces
      # Transforme les paramètres déjà filtrés (SauceParameters#permitted) en attributs pour Sauce.
      class SauceAttributesMapper
        def self.call(permitted)
          new(permitted).to_model_attributes
        end

        def initialize(permitted)
          @p = permitted
        end

        def to_model_attributes
          attrs = {}
          attrs[:name] = @p[:name] if @p.key?(:name)
          attrs[:tagline] = @p[:tagline] if @p.key?(:tagline)
          attrs[:description] = @p[:description] if @p.key?(:description)
          attrs[:characteristic] = @p[:characteristic] if @p.key?(:characteristic)
          attrs[:image_url] = @p[:image_url].presence || @p[:imageUrl] if @p.key?(:image_url) || @p.key?(:imageUrl)

          if @p.key?(:is_available) || @p.key?(:isAvailable)
            raw = if @p.key?(:is_available)
                    v = @p[:is_available]
                    if v.nil?
                      @p[:isAvailable]
                    elsif v == true || v == false
                      v
                    elsif v.respond_to?(:blank?) && v.blank?
                      @p[:isAvailable]
                    else
                      v
                    end
            else
                    @p[:isAvailable]
            end
            attrs[:is_available] = ActiveModel::Type::Boolean.new.cast(raw)
          end

          category_id = @p[:category_id].presence || @p[:categoryId]
          attrs[:category_id] = category_id if category_id.present?

          attrs[:stock_attributes] = @p[:stock] if @p[:stock].present?
          attrs[:conditionings_attributes] = @p[:conditionings] if @p[:conditionings].present?
          attrs[:ingredients_attributes] = @p[:ingredients] if @p[:ingredients].present?

          attrs
        end
      end
    end
  end
end
