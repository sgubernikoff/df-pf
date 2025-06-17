class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :jwt_authenticatable, jwt_revocation_strategy: self

    has_many :visits, dependent: :destroy

    validates :email, presence: true, uniqueness: true
    validates :name, presence: true

  def send_reset_password_instructions
    token = set_reset_password_token
    CustomDeviseMailer.reset_password_instructions(self, token).deliver_later
    token
  end

end
