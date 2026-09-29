class ScheduleProposal < ApplicationRecord
  MAX_DURATION = 2.hours

  belongs_to :conversation, inverse_of: :schedule_proposals

  enum :status, {
    pending: "pending",
    accepted: "accepted",
    declined: "declined",
    cancelled: "cancelled"
  }, validate: true

  before_validation :normalize_text

  validates :starts_at, :ends_at, :location, presence: true
  validates :location, length: { maximum: 200 }
  validates :note, length: { maximum: 1_000 }
  validate :starts_in_future, on: :create
  validate :valid_period

  def transition_from_pending!(next_status, student_seen_at: self.student_seen_at)
    with_lock do
      unless pending?
        errors.add(:status, :invalid)
        raise ActiveRecord::RecordInvalid, self
      end

      update!(status: next_status, student_seen_at: student_seen_at)
    end
  end

  private

  def normalize_text
    self.location = location.to_s.strip
    self.note = note.to_s.strip
  end

  def starts_in_future
    errors.add(:starts_at, :future) if starts_at.present? && starts_at <= Time.current
  end

  def valid_period
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, :after_start) if ends_at <= starts_at
    errors.add(:ends_at, :duration) if ends_at - starts_at > MAX_DURATION
  end
end
