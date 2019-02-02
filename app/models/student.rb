class Student < ApplicationRecord
  has_many :registrations
  has_many :teachers, through: :registrations

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Invalid email: %{value}" }
end
