class User < ApplicationRecord
  has_secure_password

  has_one :student_profile, dependent: :destroy
  has_one :company_profile, dependent: :destroy
  has_many :company_conversations,
    class_name: "Conversation",
    foreign_key: :company_id,
    dependent: :destroy,
    inverse_of: :company
  has_many :student_conversations,
    class_name: "Conversation",
    foreign_key: :student_id,
    dependent: :destroy,
    inverse_of: :student
  has_many :sent_messages,
    class_name: "Message",
    foreign_key: :sender_id,
    dependent: :destroy,
    inverse_of: :sender
  has_many :job_postings,
    foreign_key: :company_id,
    dependent: :destroy,
    inverse_of: :company
  has_many :job_posting_interests,
    foreign_key: :student_id,
    dependent: :destroy,
    inverse_of: :student
  has_many :interested_job_postings, through: :job_posting_interests, source: :job_posting
  enum :role, { student: "student", company: "company" }, validate: true

  before_validation :normalize_email

  validates :email,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
