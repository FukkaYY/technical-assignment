class Department < ApplicationRecord
  belongs_to :faculty
  has_many :student_profiles, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 200 }, uniqueness: { scope: :faculty_id }
end
