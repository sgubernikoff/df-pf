class AddDressToVisits < ActiveRecord::Migration[7.1]
  def change
    add_reference :visits, :dress, foreign_key: true
  end
end
