class AddUserToVisits < ActiveRecord::Migration[7.1]
  def change
    add_reference :visits, :user, null: false, foreign_key: true
  end
end
