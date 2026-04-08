# frozen_string_literal: true

# Sauces use UUID primary keys; the default Active Storage migration used bigint for
# `record_id`, so attachments never matched `Sauce.find` and `image_url` was nil on show/index.
# String `record_id` matches Rails’ polymorphic storage for UUID (and still works for integer PKs).
class ChangeActiveStorageAttachmentsRecordIdToString < ActiveRecord::Migration[8.1]
  def up
    ActiveStorage::Attachment.delete_all
    ActiveStorage::Blob.delete_all

    remove_index :active_storage_attachments, name: "index_active_storage_attachments_uniqueness"

    change_column :active_storage_attachments, :record_id, :string, null: false

    add_index :active_storage_attachments,
              %i[record_type record_id name blob_id],
              unique: true,
              name: "index_active_storage_attachments_uniqueness"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
