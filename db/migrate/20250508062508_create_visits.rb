class CreateVisits < ActiveRecord::Migration[7.1]
  def change
    create_table :visits do |t|
      t.string :customer_name
      t.string :customer_email
      t.text :notes
      t.references :dress, null: false, foreign_key: true

      t.timestamps
    end
  end
end
