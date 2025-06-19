class AddPriceToVisits < ActiveRecord::Migration[7.1]
  def change
    add_column :visits, :price, :string
  end
end
