class ChangePriceToStringInDresses < ActiveRecord::Migration[7.1]
  def change
    change_column :dresses, :price, :string
  end
end
