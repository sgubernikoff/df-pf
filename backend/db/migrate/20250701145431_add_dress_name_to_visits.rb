class AddDressNameToVisits < ActiveRecord::Migration[7.1]
  def change
    add_column :visits, :dress_name, :string
  end
end
