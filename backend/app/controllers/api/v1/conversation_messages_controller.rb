module Api
  module V1
    class ConversationMessagesController < ApplicationController
      before_action :require_student
      before_action :set_conversation

      def create
        return unless @conversation

        message = @conversation.messages.create!(message_params.merge(sender: current_user))

        render json: { data: { message: message_json(message) } }, status: :created
      rescue ActiveRecord::RecordInvalid => error
        render json: { errors: validation_errors(error.record.errors) }, status: :unprocessable_entity
      end

      private

      def set_conversation
        @conversation = current_user.student_conversations.find_by(id: params[:conversation_id])
        return if @conversation

        render json: {
          errors: [{ field: "conversation", code: "not_found", message: "会話が見つかりません" }]
        }, status: :not_found
      end

      def message_params
        params.require(:message).permit(:body)
      end

      def message_json(message)
        {
          id: message.id,
          body: message.body,
          sent_at: message.created_at.utc.iso8601,
          sender_role: message.sender.role
        }
      end
    end
  end
end
