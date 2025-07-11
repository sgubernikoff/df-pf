# app/models/user_assignment.rb
class UserAssignment < ApplicationRecord
    belongs_to :salesperson, class_name: 'User'
    belongs_to :client, class_name: 'User'
  
    # Validations
    validates :client_id, uniqueness: true
    validate :salesperson_must_be_admin
    validate :client_must_not_be_admin
    validate :users_must_be_different
  
    private
  
    def salesperson_must_be_admin
      return unless salesperson
      
      errors.add(:salesperson, 'must be a salesperson') unless salesperson.is_admin?
    end
  
    def client_must_not_be_admin
      return unless client
      
      errors.add(:client, 'must be a client') unless client.is_admin == false
    end
  
    def users_must_be_different
      return unless salesperson && client
      
      errors.add(:client, 'cannot be the same as salesperson') if salesperson_id == client_id
    end
  end