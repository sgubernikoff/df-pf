class UpdateForeignKeyOnVisits < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :visits, :users
    add_foreign_key :visits, :users, on_delete: :cascade
  end
end
