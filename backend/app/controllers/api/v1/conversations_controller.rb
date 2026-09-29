module Api
  module V1
    class ConversationsController < ApplicationController
      before_action :require_student

      def index
        conversations = current_user.student_conversations
          .includes(:schedule_proposals, company: :company_profile, messages: :sender)
          .sort_by { |conversation| [conversation.latest_activity_at, conversation.id] }
          .reverse

        render json: {
          data: conversations.filter_map { |conversation| list_item_json(conversation) }
        }
      end

      def show
        conversation = current_user.student_conversations
          .includes(:schedule_proposals, company: :company_profile, messages: :sender)
          .find_by(id: params[:id])

        unless conversation
          render json: {
            errors: [{ field: "conversation", code: "not_found", message: "会話が見つかりません" }]
          }, status: :not_found
          return
        end

        render json: {
          data: {
            id: conversation.id,
            company: company_json(conversation.company),
            messages: conversation.messages.map { |message| message_json(message) },
            schedule_proposals: conversation.schedule_proposals.map { |proposal| schedule_proposal_json(proposal) }
          }
        }
      end

      def mark_read
        conversation = current_user.student_conversations.find_by(id: params[:id])

        unless conversation
          render json: {
            errors: [{ field: "conversation", code: "not_found", message: "会話が見つかりません" }]
          }, status: :not_found
          return
        end

        message = conversation.messages.find_by(id: read_params[:message_id])
        unless message
          render json: {
            errors: [{ field: "message_id", code: "invalid", message: "既読にするメッセージが正しくありません" }]
          }, status: :unprocessable_entity
          return
        end

        conversation.mark_read_by_student!(message)
        render json: { data: { unread_count: conversation.student_unread_count } }
      end

      def mark_schedule_proposals_seen
        conversation = current_user.student_conversations.find_by(id: params[:id])

        unless conversation
          render json: {
            errors: [{ field: "conversation", code: "not_found", message: "会話が見つかりません" }]
          }, status: :not_found
          return
        end

        proposal = conversation.schedule_proposals.find_by(id: schedule_proposal_seen_params[:schedule_proposal_id])
        unless proposal
          render json: {
            errors: [{ field: "schedule_proposal_id", code: "invalid", message: "確認済みにする面談提案が正しくありません" }]
          }, status: :unprocessable_entity
          return
        end

        conversation.mark_schedule_proposals_seen_by_student!(proposal)
        render json: { data: { unseen_schedule_proposal_count: conversation.student_unseen_schedule_proposal_count } }
      end

      private

      def list_item_json(conversation)
        latest_message = conversation.messages.last
        return unless latest_message

        {
          id: conversation.id,
          company: company_json(conversation.company),
          latest_message_excerpt: latest_message.body.truncate(120, omission: "…"),
          latest_message_sent_at: latest_message.created_at.utc.iso8601,
          latest_activity_at: conversation.latest_activity_at.utc.iso8601,
          unread_count: conversation.student_unread_count,
          unseen_schedule_proposal_count: conversation.student_unseen_schedule_proposal_count
        }
      end

      def read_params
        params.require(:conversation).permit(:message_id)
      end

      def schedule_proposal_seen_params
        params.require(:conversation).permit(:schedule_proposal_id)
      end

      def company_json(company)
        {
          company_name: company.company_profile.company_name
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
