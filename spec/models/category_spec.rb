# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category, type: :model do
  before do
    Sauce.delete_all
    Category.delete_all
  end

  describe "valid category" do
    it "persists a category with a name" do
      category = build_category
      expect(category.save).to be true
      category.reload
      expect(category.name).to eq("Piquantes")
    end
  end

  describe "name" do
    it "rejects blank name" do
      category = build_category(name: "")
      expect(category.save).to be false
      expect(category.errors[:name]).to be_present
    end

    it "rejects name longer than 50 characters" do
      category = build_category(name: "a" * 51)
      expect(category.save).to be false
      expect(category.errors[:name]).to be_present
    end

    it "accepts name exactly 50 characters" do
      category = build_category(name: "a" * 50)
      expect(category.save).to be true
      expect(category.reload.name.length).to eq(50)
    end

    it "rejects duplicate name" do
      Category.create!(valid_attributes.merge(name: "UniqueName"))

      category = build_category(name: "UniqueName")
      expect(category.save).to be false
      expect(category.errors[:name]).to be_present
    end
  end

  describe "associations" do
    it "has many sauces" do
      category = Category.create!(valid_attributes)
      Sauce.create!(name: "Sauce A", tagline: "First.", category: category, is_available: true)
      Sauce.create!(name: "Sauce B", tagline: "Second.", category: category, is_available: true)

      expect(category.sauces.count).to eq(2)
      expect(category.sauces.pluck(:name)).to contain_exactly("Sauce A", "Sauce B")
    end

    it "raises when destroying a category that still has sauces" do
      category = Category.create!(valid_attributes)
      Sauce.create!(name: "Bound", tagline: "Tag.", category: category, is_available: true)

      expect { category.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it "allows destroy when the category has no sauces" do
      category = Category.create!(valid_attributes)

      expect { category.destroy! }.not_to raise_error
      expect(described_class.find_by(id: category.id)).to be_nil
    end
  end

  def valid_attributes(overrides = {})
    { name: "Piquantes" }.merge(overrides)
  end

  def build_category(overrides = {})
    described_class.new(valid_attributes(overrides))
  end
end
