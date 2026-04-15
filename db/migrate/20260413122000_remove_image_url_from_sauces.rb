# frozen_string_literal: true

class RemoveImageUrlFromSauces < ActiveRecord::Migration[8.1]
  def change
    remove_column :sauces, :image_url, :text
  end
end
