# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Sauces::SauceReloader do
  describe ".with_includes!" do
    it "returns the same Sauce instance when given a Sauce (no find / preload)" do
      sauce = create(:sauce)

      result = described_class.with_includes!(sauce)

      expect(result).to be(sauce)
    end

    it "finds by id with category, stock, conditionings, ingredients, and image_attachment+blob preloaded" do
      category = create(:category)
      sauce = create(:sauce, category: category)
      create(:stock, sauce: sauce)
      create(:conditioning, sauce: sauce)
      create(:ingredient, sauce: sauce)
      sauce.image.attach(
        io: StringIO.new("x"),
        filename: "spec.png",
        content_type: "image/png"
      )

      reloaded = described_class.with_includes!(sauce.id)

      expect(reloaded.id).to eq(sauce.id)
      expect(reloaded.association(:category).loaded?).to be true
      expect(reloaded.association(:stock).loaded?).to be true
      expect(reloaded.association(:conditionings).loaded?).to be true
      expect(reloaded.association(:ingredients).loaded?).to be true
      expect(reloaded.association(:image_attachment).loaded?).to be true
      expect(reloaded.image_attachment.association(:blob).loaded?).to be true
      expect(reloaded.image).to be_attached
    end

    it "raises ActiveRecord::RecordNotFound when the id does not exist" do
      expect { described_class.with_includes!(SecureRandom.uuid) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
