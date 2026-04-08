# frozen_string_literal: true

RSpec.shared_context "API V1 sauces resource request setup" do
  include_context "API V1 sauces catalog admin and customer users"

  let!(:category) { create(:category, name: "Cat Sauces API Main") }
end
