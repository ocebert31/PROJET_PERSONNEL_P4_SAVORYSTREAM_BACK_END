# frozen_string_literal: true

class CreateCatalogTables < ActiveRecord::Migration[8.1]
  def change
    create_table :categories, id: :uuid do |t|
      t.string :name, null: false, limit: 50
      t.timestamps
    end
    add_index :categories, :name, unique: true

    create_table :sauces, id: :uuid do |t|
      t.string :name, null: false, limit: 50
      t.string :tagline, null: false, limit: 120
      t.text :description
      t.string :characteristic, limit: 255
      t.text :image_url
      t.boolean :is_available, null: false, default: true
      t.references :category, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
    add_index :sauces, :name, unique: true

    create_table :stocks, id: :uuid do |t|
      t.integer :quantity, null: false
      t.references :sauce, type: :uuid, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end

    create_table :conditionings, id: :uuid do |t|
      t.string :volume, null: false, limit: 20
      t.decimal :price, null: false, precision: 10, scale: 2
      t.references :sauce, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    create_table :ingredients, id: :uuid do |t|
      t.string :name, null: false, limit: 100
      t.string :quantity, null: false, limit: 100
      t.references :sauce, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
  end
end
