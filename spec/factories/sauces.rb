# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
  end

  factory :sauce do
    category
    sequence(:name) { |n| "Sauce #{n}" }
    tagline { "Tagline for spec." }
    is_available { true }
  end

  factory :stock do
    sauce
    quantity { 10 }
  end

  factory :conditioning do
    sauce
    volume { "250ml" }
    price { 6.99 }
  end

  factory :ingredient do
    sauce
    sequence(:name) { |n| "Ingredient #{n}" }
    quantity { "10%" }
  end
end
