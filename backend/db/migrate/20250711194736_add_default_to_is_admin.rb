class AddDefaultToIsAdmin < ActiveRecord::Migration[7.1]
  def up
    # Add default value of false to is_admin column
    change_column_default :users, :is_admin, false
    
    # Update any existing NULL values to false (making them clients)
    User.where(is_admin: nil).update_all(is_admin: false)
  end

  def down
    # Remove the default value (back to no default)
    change_column_default :users, :is_admin, nil
  end
end