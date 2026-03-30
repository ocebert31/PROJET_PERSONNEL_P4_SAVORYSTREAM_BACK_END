# frozen_string_literal: true

class RenameRefreshTokensToUsersAuthentification < ActiveRecord::Migration[8.1]
  def change
    rename_table :refresh_tokens, :users_authentification
  end
end
