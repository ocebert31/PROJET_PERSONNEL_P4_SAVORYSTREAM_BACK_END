# frozen_string_literal: true

RSpec.shared_context "API V1 sauces conditioning request setup" do
  include_context "API V1 sauces catalog admin and customer users"

  let!(:category) { create(:category, name: "Piquantes Conditioning") }
  let!(:sauce) do
    create(
      :sauce,
      name: "Sriracha Conditioning Spec",
      tagline: "Tagline for conditioning API.",
      category: category,
      is_available: true
    )
  end
end
