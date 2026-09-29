module Api
  module V1
    class StudentScheduleProposalsController < ApplicationController
      before_action :require_student

      def accept
        transition(:accepted)
      end

      def decline
        transition(:declined)
      end

      private

      def transition(next_status)
        proposal = ScheduleProposal.joins(:conversation).find_by(
          id: params[:id], conversations: { student_id: current_user.id }
        )
        unless proposal
          render json: {
            errors: [{ field: "schedule_proposal", code: "not_found", message: "予定が見つかりません" }]
          }, status: :not_found
          return
        end

        proposal.transition_from_pending!(next_status, student_seen_at: Time.current)
        render json: { data: schedule_proposal_json(proposal) }
      rescue ActiveRecord::RecordInvalid
        render json: {
          errors: [{ field: "status", code: "invalid", message: "回答済みまたは取消済みの予定は変更できません" }]
        }, status: :unprocessable_entity
      end

      def schedule_proposal_json(proposal)
        proposal.as_json(only: %i[id starts_at ends_at location note status created_at])
      end
    end
  end
end
