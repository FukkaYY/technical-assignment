class CompanyProfile < ApplicationRecord
  belongs_to :user

  before_validation :normalize_company_name

  validates :company_name, presence: true, length: { maximum: 200 }
  validate :user_is_company

  private

  def normalize_company_name
    self.company_name = company_name.to_s.strip
  end

  def user_is_company
    errors.add(:user, :invalid) if user.present? && !user.company?
  end
end
