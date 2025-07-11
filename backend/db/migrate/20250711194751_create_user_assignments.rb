# Replace the existing CreateUserAssignments migration with this:

class CreateUserAssignments < ActiveRecord::Migration[7.1]
  def up
    # Check if table exists before creating it
    unless table_exists?(:user_assignments)
      create_table :user_assignments do |t|
        t.references :salesperson, null: false, foreign_key: { to_table: :users }
        t.references :client, null: false, foreign_key: { to_table: :users }
        t.timestamps
      end
    end

    # Remove any existing conflicting indexes
    begin
      remove_index :user_assignments, :client_id if index_exists?(:user_assignments, :client_id)
    rescue ActiveRecord::StatementInvalid
      # Index might not exist in Rails but exist in DB
    end

    begin
      remove_index :user_assignments, :salesperson_id if index_exists?(:user_assignments, :salesperson_id)
    rescue ActiveRecord::StatementInvalid
      # Index might not exist in Rails but exist in DB
    end

    # Now create the indexes we want
    add_index :user_assignments, :client_id, unique: true
    add_index :user_assignments, :salesperson_id
  end

  def down
    drop_table :user_assignments if table_exists?(:user_assignments)
  end
end