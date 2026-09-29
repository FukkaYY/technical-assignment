class StudentRegistration
  attr_reader :user, :student_profile

  def initialize(user_attributes:, profile_attributes:)
    @user = User.new(user_attributes.merge(role: :student))
    @student_profile = user.build_student_profile(profile_attributes)
  end

  def save
    valid = user.valid?
    valid = student_profile.valid? && valid
    return false unless valid

    User.transaction do
      user.save!
      student_profile.save!
    end

    true
  end

  def errors
    user_errors = user.errors.map { |error| [error.attribute, error.type, error.full_message] }
    profile_errors = student_profile.errors.map { |error| [error.attribute, error.type, error.full_message] }
    user_errors + profile_errors
  end
end
