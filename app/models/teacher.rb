class Teacher < ApplicationRecord
  has_many :registrations
  has_many :students, through: :registrations

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Invalid email: %{value}" }
end