module Api
  module V1
    module Company
      class ConversationsController < ApplicationController
        before_action :require_company

        def index
          conversations = current_user.company_conversations
            .includes(student: :student_profile, messages: :sender)
            .sort_by { |conversation| [conversation.messages.last&.created_at || conversation.created_at, conversation.id] }
            .reverse

          render json: { data: conversations.filter_map { |conversation| list_item_json(conversation) } }
        end

        private

        def list_item_json(conversation)
          latest_message = conversation.messages.last
          return unless latest_message

          {
            id: conversation.id,
            student: {
              id: conversation.student_id,
              name: conversation.student.student_profile.name
            },
            latest_message_excerpt: latest_message.body.truncate(120, omission: "…"),
            latest_message_sent_at: latest_message.created_at.utc.iso8601,
            latest_sender_role: latest_message.sender.role
          }
        end
      end
    end
  end
end
