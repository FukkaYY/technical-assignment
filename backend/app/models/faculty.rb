class Faculty < ApplicationRecord
  belongs_to :school
  has_many :departments, dependent: :destroy
  has_many :student_profiles, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 200 }, uniqueness: { scope: :school_id }
end
