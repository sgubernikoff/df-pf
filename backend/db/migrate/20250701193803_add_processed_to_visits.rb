class AddProcessedToVisits < ActiveRecord::Migration[7.0]
  def change
    add_column :visits, :processed, :boolean, default: false, null: false
  end
end
