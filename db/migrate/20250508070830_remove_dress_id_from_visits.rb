class RemoveDressIdFromVisits < ActiveRecord::Migration[7.1]
  def change
    remove_column :visits, :dress_id, :integer
  end
end
