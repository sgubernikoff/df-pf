class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :jwt_authenticatable, jwt_revocation_strategy: self

  # Associations for salespeople
  has_many :salesperson_assignments, class_name: 'UserAssignment', foreign_key: 'salesperson_id', dependent: :destroy
  has_many :assigned_clients, through: :salesperson_assignments, source: :client
  
  # Association for clients
  has_one :client_assignment, class_name: 'UserAssignment', foreign_key: 'client_id', dependent: :destroy
  has_one :assigned_salesperson, through: :client_assignment, source: :salesperson

  # Scopes
  scope :salespeople, -> { where(is_admin: true) }
  scope :clients, -> { where(is_admin: false) }
  scope :unassigned_clients, -> { clients.left_joins(:client_assignment).where(user_assignments: { id: nil }) }

  has_many :visits, dependent: :destroy

  # Validations
  validate :client_must_have_salesperson_assignment, if: :client_and_persisted?
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  def send_reset_password_instructions
    token = set_reset_password_token
    CustomDeviseMailer.reset_password_instructions(self, token).deliver_later
    token
  end

  def salesperson?
    is_admin == true
  end

  def client?
    is_admin != true
  end

  def salesperson
    assigned_salesperson
  end

  def clients
    assigned_clients
  end

  def assign_to_salesperson!(salesperson_user)
    raise ArgumentError, 'User is already a salesperson' if salesperson?
    raise ArgumentError, 'Target user is not a salesperson' unless salesperson_user.salesperson?
    
    UserAssignment.create!(salesperson: salesperson_user, client: self)
  end

  def unassign_from_salesperson!
    client_assignment&.destroy!
  end

  private

  def client_and_persisted?
    client? && persisted?
  end

  def client_must_have_salesperson_assignment
    return unless client?
    
    errors.add(:base, 'Clients must be assigned to a salesperson') unless assigned_salesperson
  end

end
