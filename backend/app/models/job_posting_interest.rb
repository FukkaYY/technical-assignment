class JobPostingInterest < ApplicationRecord
  belongs_to :student, class_name: "User", inverse_of: :job_posting_interests
  belongs_to :job_posting, inverse_of: :job_posting_interests

  validates :job_posting_id, uniqueness: { scope: :student_id }
  validate :student_has_student_role

  private

  def student_has_student_role
    errors.add(:student, :invalid) if student.present? && !student.student?
  end
end
