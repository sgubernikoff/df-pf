class RemoveCustomerFieldsFromVisits < ActiveRecord::Migration[7.1]
  def change
    remove_column :visits, :customer_name, :string
    remove_column :visits, :customer_email, :string
  end
end
