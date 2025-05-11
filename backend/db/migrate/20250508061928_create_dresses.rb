class CreateDresses < ActiveRecord::Migration[7.1]
  def change
    create_table :dresses do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :image_urls, array: true, default: []

      t.timestamps
    end
  end
end
