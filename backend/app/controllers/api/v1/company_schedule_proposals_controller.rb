module Api
  module V1
    class CompanyScheduleProposalsController < ApplicationController
      JAPAN_TIME_ZONE = ActiveSupport::TimeZone["Asia/Tokyo"]
      ALLOWED_DURATIONS = (15..120).step(15).to_a.freeze

      before_action :require_company

      def create
        student = User.student.find_by(id: params[:student_id])
        unless student
          render_not_found
          return
        end

        conversation = current_user.company_conversations.find_by(student: student)
        unless conversation
          render json: {
            errors: [{ field: "conversation", code: "required", message: "先に学生へメッセージを送信してください" }]
          }, status: :unprocessable_entity
          return
        end

        attributes = parsed_params
        return unless attributes

        proposal = conversation.schedule_proposals.new(attributes)
        if proposal.save
          render json: { data: schedule_proposal_json(proposal) }, status: :created
        else
          render json: { errors: schedule_validation_errors(proposal) }, status: :unprocessable_entity
        end
      end

      def cancel
        proposal = ScheduleProposal.joins(:conversation).find_by(
          id: params[:id], conversations: { company_id: current_user.id }
        )
        unless proposal
          render_not_found
          return
        end

        proposal.transition_from_pending!(:cancelled)
        render json: { data: schedule_proposal_json(proposal) }
      rescue ActiveRecord::RecordInvalid => error
        render json: { errors: schedule_validation_errors(error.record) }, status: :unprocessable_entity
      end

      private

      def proposal_params
        params.require(:schedule_proposal).permit(:starts_at, :duration_minutes, :location, :note)
      end

      def parsed_params
        values = proposal_params
        duration_value = values[:duration_minutes].to_s
        unless duration_value.match?(/\A\d+\z/) && ALLOWED_DURATIONS.include?(duration_value.to_i)
          render_parameter_error("duration_minutes", "所要時間は15分刻みで2時間以内から選択してください")
          return nil
        end

        starts_at = parse_japan_time(values[:starts_at])
        unless starts_at
          render_parameter_error("starts_at", "開始日時を入力してください")
          return nil
        end
        if starts_at.min % 15 != 0 || starts_at.sec != 0
          render_parameter_error("starts_at", "開始日時は15分刻みで指定してください")
          return nil
        end

        values.except(:duration_minutes).merge(
          starts_at: starts_at,
          ends_at: starts_at + duration_value.to_i.minutes
        )
      end

      def parse_japan_time(value)
        JAPAN_TIME_ZONE.strptime(value.to_s, "%Y-%m-%dT%H:%M")
      rescue ArgumentError
        nil
      end

      def render_not_found
        render json: {
          errors: [{ field: "schedule_proposal", code: "not_found", message: "予定が見つかりません" }]
        }, status: :not_found
      end

      def render_parameter_error(field, message)
        render json: {
          errors: [{ field: field, code: "invalid", message: message }]
        }, status: :unprocessable_entity
      end

      def schedule_validation_errors(proposal)
        proposal.errors.map do |error|
          message = case [error.attribute, error.type]
          when [:starts_at, :blank] then "開始日時を入力してください"
          when [:starts_at, :future] then "開始日時は未来の日時を指定してください"
          when [:ends_at, :blank] then "終了日時を入力してください"
          when [:ends_at, :after_start] then "終了日時は開始日時より後にしてください"
          when [:ends_at, :duration] then "予定時間は2時間以内にしてください"
          when [:location, :blank] then "実施方法・場所を入力してください"
          when [:location, :too_long] then "実施方法・場所が上限文字数を超えています"
          when [:note, :too_long] then "補足が上限文字数を超えています"
          when [:status, :invalid] then "回答済みまたは取消済みの予定は変更できません"
          else error.message
          end
          { field: error.attribute.to_s, code: error.type.to_s, message: message }
        end
      end

      def schedule_proposal_json(proposal)
        proposal.as_json(only: %i[id starts_at ends_at location note status created_at])
      end
    end
  end
end
