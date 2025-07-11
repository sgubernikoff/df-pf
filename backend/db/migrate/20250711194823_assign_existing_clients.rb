class AssignExistingClients < ActiveRecord::Migration[7.1]
  def up
    # Find the first salesperson to assign existing clients to
    salesperson = User.find_by(is_admin: true)
    
    if salesperson
      # Assign all existing clients to the first salesperson
      User.where(is_admin: false).find_each do |client|
        UserAssignment.create!(
          salesperson: salesperson,
          client: client
        )
      end
    else
      # If no salesperson exists, you might want to handle this case
      puts "Warning: No salesperson found to assign clients to"
    end
  end

  def down
    # Remove all user assignments
    UserAssignment.destroy_all
  end
end