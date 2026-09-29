class JobPosting < ApplicationRecord
  belongs_to :company, class_name: "User", inverse_of: :job_postings
  has_many :job_posting_interests, dependent: :destroy, inverse_of: :job_posting
  has_one_attached :thumbnail

  enum :status, { published: "published", closed: "closed" }, validate: true

  before_validation :normalize_fields

  validates :title, presence: true, length: { maximum: 120 }
  validates :role_name, presence: true, length: { maximum: 100 }
  validates :work_location, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { maximum: 5_000 }
  validates :requirements, presence: true, length: { maximum: 3_000 }
  validate :company_has_company_role
  validate :acceptable_thumbnail

  private

  def normalize_fields
    %i[title role_name work_location description requirements].each do |field|
      self[field] = self[field].to_s.strip
    end
  end

  def company_has_company_role
    errors.add(:company, :invalid) if company.present? && !company.company?
  end

  def acceptable_thumbnail
    return unless thumbnail.attached?

    errors.add(:thumbnail, :invalid) unless thumbnail.blob.content_type.in?(%w[image/jpeg image/png image/webp])
    errors.add(:thumbnail, :too_large) if thumbnail.blob.byte_size > 5.megabytes
  end
end
