# frozen_string_literal: true

module Api
  module V1
    module Users
      class UserSerializer
        def self.call(user)
          new(user).as_json
        end

        def initialize(user)
          @user = user
        end

        def as_json
          {
            id: @user.id,
            first_name: @user.first_name,
            last_name: @user.last_name,
            email: @user.email,
            phone_number: @user.phone_number,
            role: @user.role,
            created_at: @user.created_at,
            updated_at: @user.updated_at
          }
        end
      end
    end
  end
end
