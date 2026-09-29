class Message < ApplicationRecord
  MAX_BODY_LENGTH = 2_000

  belongs_to :conversation, inverse_of: :messages
  belongs_to :sender, class_name: "User", inverse_of: :sent_messages

  before_validation :normalize_body

  validates :body, presence: true, length: { maximum: MAX_BODY_LENGTH }
  validate :sender_participates_in_conversation

  private

  def normalize_body
    self.body = body.to_s.strip
  end

  def sender_participates_in_conversation
    return if conversation.blank? || sender.blank?
    return if [conversation.company_id, conversation.student_id].include?(sender_id)

    errors.add(:sender, :invalid)
  end
end
