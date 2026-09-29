module Api
  module V1
    class JobPostingsController < ApplicationController
      before_action :require_authentication, only: :thumbnail
      before_action :require_student, except: :thumbnail

      def index
        if params[:interested].present? && params[:interested] != "true"
          render json: {
            errors: [{ field: "interested", code: "invalid", message: "気になる募集の指定が正しくありません" }]
          }, status: :unprocessable_entity
          return
        end

        postings = JobPosting.published.includes(company: :company_profile).order(created_at: :desc, id: :desc)
        postings = postings.joins(:job_posting_interests).where(job_posting_interests: { student_id: current_user.id }) if params[:interested] == "true"
        render json: { data: postings.map { |posting| posting_json(posting) } }
      end

      def show
        posting = JobPosting.published.includes(company: :company_profile).find_by(id: params[:id])
        unless posting
          render json: {
            errors: [{ field: "job_posting", code: "not_found", message: "募集が見つかりません" }]
          }, status: :not_found
          return
        end

        render json: { data: posting_json(posting) }
      end

      def interest
        posting = student_visible_posting
        return unless posting

        current_user.job_posting_interests.find_or_create_by!(job_posting: posting)
        render json: { data: { job_posting_id: posting.id, interested: true } }, status: :created
      rescue ActiveRecord::RecordNotUnique
        render json: { data: { job_posting_id: posting.id, interested: true } }, status: :created
      end

      def destroy_interest
        posting = student_visible_posting
        return unless posting

        current_user.job_posting_interests.find_by(job_posting: posting)&.destroy!
        render json: { data: { job_posting_id: posting.id, interested: false } }
      end

      def thumbnail
        posting = JobPosting.find_by(id: params[:id])
        permitted = posting && (posting.published? || (current_user.company? && posting.company_id == current_user.id))
        unless permitted && posting.thumbnail.attached?
          head :not_found
          return
        end

        send_data posting.thumbnail.download,
          type: posting.thumbnail.blob.content_type,
          disposition: "inline",
          filename: posting.thumbnail.filename.to_s
      end

      private

      def posting_json(posting)
        posting.as_json(only: %i[id title role_name work_location description requirements created_at]).merge(
          company: { company_name: posting.company.company_profile.company_name },
          interested: current_user.job_posting_interests.exists?(job_posting_id: posting.id),
          thumbnail_url: posting.thumbnail.attached? ? "/api/v1/job_postings/#{posting.id}/thumbnail" : nil
        )
      end

      def student_visible_posting
        posting = JobPosting.published.find_by(id: params[:id])
        return posting if posting

        render json: {
          errors: [{ field: "job_posting", code: "not_found", message: "募集が見つかりません" }]
        }, status: :not_found
        nil
      end
    end
  end
end
