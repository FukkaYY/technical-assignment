module Api
  module V1
    class StudentRegistrationsController < ApplicationController
      def create
        registration = StudentRegistration.new(
          user_attributes: user_params,
          profile_attributes: profile_params
        )

        if registration.save
          reset_session
          session[:user_id] = registration.user.id
          render json: {
            data: {
              user: user_json(registration.user),
              student_profile: student_profile_json(registration.student_profile)
            }
          }, status: :created
        else
          render json: { errors: validation_errors(registration.errors) }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        render json: {
          errors: [{ field: "email", code: "taken", message: "メールアドレスはすでに使用されています" }]
        }, status: :unprocessable_entity
      end

      private

      def user_params
        params.require(:student_registration).permit(:email, :password, :password_confirmation)
      end

      def profile_params
        params.require(:student_registration).permit(
          :last_name,
          :first_name,
          :school_id,
          :faculty_id,
          :department_id,
          :graduation_year,
          skills: [],
          interested_roles: []
        )
      end
    end
  end
end
