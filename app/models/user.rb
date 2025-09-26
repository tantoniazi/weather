class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :weathers
  has_many :reports

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_create :generate_authentication_token

  def generate_authentication_token
    loop do
      self.authentication_token = SecureRandom.hex(20)
      break unless User.exists?(authentication_token: authentication_token)
    end
  end

  # Optional: refresh token when needed
  def reset_authentication_token!
    update(authentication_token: SecureRandom.hex(20))
  end
end