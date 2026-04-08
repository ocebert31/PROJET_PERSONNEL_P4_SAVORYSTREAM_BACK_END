# frozen_string_literal: true

module Api
  module V1
    module Sauces
      class ConditioningSerializer
        def self.call(conditioning)
          new(conditioning).as_json
        end

        def initialize(conditioning)
          @conditioning = conditioning
        end

        def as_json
          {
            id: @conditioning.id,
            volume: @conditioning.volume,
            price: @conditioning.price.to_s,
            sauce_id: @conditioning.sauce_id,
            created_at: @conditioning.created_at,
            updated_at: @conditioning.updated_at
          }
        end
      end
    end
  end
end
