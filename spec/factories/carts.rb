# frozen_string_literal: true

FactoryBot.define do
  factory :cart do
    user
    guest_id { nil }

    trait :guest_owned do
      user { nil }
      sequence(:guest_id) { |n| "guest-#{n}" }
    end

    # Fixed guest_id for specs that need a stable cookie ↔ cart link (e.g. current cart).
    trait :stable_guest do
      guest_owned
      guest_id { "guest-stable" }
    end
  end

  factory :cart_sauce do
    cart
    sauce { association(:sauce) }
    conditioning { association(:conditioning, sauce: sauce) }
    quantity { 1 }
    price { conditioning.price }
  end
end
