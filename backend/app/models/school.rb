class School < ApplicationRecord
  TYPES = {
    "technical_college" => "高専",
    "vocational_school" => "専門学校",
    "junior_college" => "短期大学",
    "university" => "大学",
    "graduate_school" => "大学院"
  }.freeze

  has_many :faculties, dependent: :destroy
  has_many :student_profiles, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 200 }, uniqueness: { scope: :school_type }
  validates :school_type, inclusion: { in: TYPES.keys }
end
