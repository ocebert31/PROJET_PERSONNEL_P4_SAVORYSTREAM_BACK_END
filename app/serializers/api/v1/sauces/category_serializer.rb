# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class CategorySerializer
        def self.call(category)
          new(category).as_json
        end

        def initialize(category)
          @category = category
        end

        def as_json
          {
            id: @category.id,
            name: @category.name,
            created_at: @category.created_at,
            updated_at: @category.updated_at
          }
        end
      end
    end
  end
end
