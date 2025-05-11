class DropJoinTableDressesVisits < ActiveRecord::Migration[7.1]
  def change
    drop_table :dresses_visits
  end
end
