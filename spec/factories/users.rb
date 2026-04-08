# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { "Jane" }
    last_name { "Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:phone_number) { |n| format("06%08d", n) }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    role { :customer }

    trait :admin do
      role { :admin }
    end
  end
end
