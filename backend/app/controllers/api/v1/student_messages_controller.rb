module Api
  module V1
    class StudentMessagesController < ApplicationController
      before_action :require_company
      before_action :set_student

      def index
        return unless @student

        conversation = current_user.company_conversations
          .includes(:schedule_proposals, messages: :sender)
          .find_by(student: @student)

        render json: {
          data: {
            student: student_json(@student),
            conversation_id: conversation&.id,
            messages: conversation ? conversation.messages.map { |message| message_json(message) } : [],
            schedule_proposals: conversation ? conversation.schedule_proposals.map { |proposal| schedule_proposal_json(proposal) } : []
          }
        }
      end

      def create
        return unless @student

        conversation = nil
        message = nil

        ApplicationRecord.transaction do
          conversation = current_user.company_conversations.find_or_create_by!(student: @student)
          message = conversation.messages.create!(message_params.merge(sender: current_user))
        end

        render json: {
          data: {
            conversation_id: conversation.id,
            message: message_json(message)
          }
        }, status: :created
      rescue ActiveRecord::RecordInvalid => error
        render json: { errors: validation_errors(error.record.errors) }, status: :unprocessable_entity
      end

      private

      def set_student
        @student = User.student.includes(:student_profile).find_by(id: params[:student_id])
        if @student && (@student.student_profile.visible_to_companies? || current_user.company_conversations.exists?(student: @student))
          return
        end

        @student = nil

        render json: {
          errors: [{ field: "student", code: "not_found", message: "学生が見つかりません" }]
        }, status: :not_found
      end

      def message_params
        params.require(:message).permit(:body)
      end

      def student_json(student)
        {
          id: student.id,
          name: student.student_profile.name
        }
      end

      def message_json(message)
        {
          id: message.id,
          body: message.body,
          sent_at: message.created_at.utc.iso8601,
          sender_role: message.sender.role
        }
      end

      def schedule_proposal_json(proposal)
        proposal.as_json(only: %i[id starts_at ends_at location note status created_at])
      end
    end
  end
end
