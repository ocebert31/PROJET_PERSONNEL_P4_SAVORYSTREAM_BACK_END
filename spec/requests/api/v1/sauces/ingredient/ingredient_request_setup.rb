# frozen_string_literal: true

RSpec.shared_context "API V1 sauces ingredient request setup" do
  include_context "API V1 sauces catalog admin and customer users"

  let!(:category) { create(:category, name: "Cat Ingredient API") }
  let!(:sauce) do
    create(
      :sauce,
      name: "Sriracha Ingredient API Spec",
      tagline: "Tagline for ingredient API.",
      category: category,
      is_available: true
    )
  end
end
