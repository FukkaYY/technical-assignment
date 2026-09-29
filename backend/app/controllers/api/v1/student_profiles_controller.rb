module Api
  module V1
    class StudentProfilesController < ApplicationController
      before_action :require_student

      def update
        profile = current_user.student_profile

        if profile.update(profile_params)
          render json: { data: student_profile_json(profile) }
        else
          render json: { errors: validation_errors(profile.errors) }, status: :unprocessable_entity
        end
      end

      def update_visibility
        profile = current_user.student_profile
        visibility = visibility_params[:visible_to_companies]
        unless visibility == true || visibility == false
          render json: { errors: [{ field: "visible_to_companies", code: "invalid", message: "公開状態が正しくありません" }] }, status: :unprocessable_entity
          return
        end

        if profile.update(visible_to_companies: visibility)
          render json: { data: student_profile_json(profile) }
        else
          render json: { errors: validation_errors(profile.errors) }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.require(:student_profile).permit(
          :last_name,
          :first_name,
          :school_id,
          :faculty_id,
          :department_id,
          :graduation_year,
          :self_introduction,
          :self_promotion,
          :student_achievement,
          :research_summary,
          :english_skills,
          :qualifications,
          skills: [],
          interested_roles: []
        )
      end

      def visibility_params
        params.require(:student_profile).permit(:visible_to_companies)
      end
    end
  end
end
