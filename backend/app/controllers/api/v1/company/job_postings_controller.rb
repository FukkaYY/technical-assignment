module Api
  module V1
    module Company
      class JobPostingsController < ApplicationController
        before_action :require_company
        before_action :set_job_posting, only: %i[show update close]

        def index
          postings = current_user.job_postings.order(created_at: :desc, id: :desc)
          render json: { data: postings.map { |posting| posting_json(posting) } }
        end

        def show
          render json: { data: posting_json(@job_posting) }
        end

        def create
          posting = current_user.job_postings.new(job_posting_params.merge(status: :published))
          posting.thumbnail.attach(params.dig(:job_posting, :thumbnail)) if params.dig(:job_posting, :thumbnail).present?

          if posting.save
            render json: { data: posting_json(posting) }, status: :created
          else
            render json: { errors: validation_errors(posting.errors) }, status: :unprocessable_entity
          end
        end

        def update
          @job_posting.thumbnail.attach(params.dig(:job_posting, :thumbnail)) if params.dig(:job_posting, :thumbnail).present?
          if @job_posting.update(job_posting_params)
            @job_posting.thumbnail.purge if remove_thumbnail?
            render json: { data: posting_json(@job_posting) }
          else
            render json: { errors: validation_errors(@job_posting.errors) }, status: :unprocessable_entity
          end
        end

        def close
          @job_posting.closed!
          render json: { data: posting_json(@job_posting) }
        end

        private

        def set_job_posting
          @job_posting = current_user.job_postings.find_by(id: params[:id])
          return if @job_posting

          render json: {
            errors: [{ field: "job_posting", code: "not_found", message: "募集が見つかりません" }]
          }, status: :not_found
        end

        def job_posting_params
          params.require(:job_posting).permit(:title, :role_name, :work_location, :description, :requirements)
        end

        def remove_thumbnail?
          ActiveModel::Type::Boolean.new.cast(params.dig(:job_posting, :remove_thumbnail)) && params.dig(:job_posting, :thumbnail).blank?
        end

        def posting_json(posting)
          posting.as_json(only: %i[id title role_name work_location description requirements status created_at updated_at]).merge(
            thumbnail_url: posting.thumbnail.attached? ? "/api/v1/job_postings/#{posting.id}/thumbnail" : nil
          )
        end
      end
    end
  end
end
