class AddShopifyDressIdToVisits < ActiveRecord::Migration[7.1]
  def change
    add_column :visits, :shopify_dress_id, :string
    add_index :visits, :shopify_dress_id
  end
end
