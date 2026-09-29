module Api
  module V1
    class StudentsController < ApplicationController
      PER_PAGE = 20

      before_action :require_company

      def index
        page = parsed_page
        return unless page
        filters = parsed_filters
        return unless filters

        scope = StudentProfile.visible_to_companies.includes(:user, :school, :faculty, :department).order(created_at: :desc, id: :desc)
        scope = apply_filters(scope, filters)
        total_count = scope.count
        total_pages = (total_count.to_f / PER_PAGE).ceil
        profiles = scope.offset((page - 1) * PER_PAGE).limit(PER_PAGE)

        render json: {
          data: profiles.map { |profile| list_item_json(profile) },
          meta: {
            page: page,
            per_page: PER_PAGE,
            total_count: total_count,
            total_pages: total_pages,
            has_previous: page > 1,
            has_next: page < total_pages
          }
        }
      end

      def show
        profile = StudentProfile.visible_to_companies.find_by(user_id: params[:id])
        unless profile
          render json: {
            errors: [{ field: "student", code: "not_found", message: "学生が見つかりません" }]
          }, status: :not_found
          return
        end

        render json: { data: detail_json(profile) }
      end

      private

      def parsed_page
        value = params[:page]
        return 1 if value.nil?
        return value.to_i if value.to_s.match?(/\A[1-9]\d*\z/)

        render json: {
          errors: [{ field: "page", code: "invalid", message: "ページ番号は1以上の整数で指定してください" }]
        }, status: :unprocessable_entity
        nil
      end

      def parsed_filters
        school_type = params[:school_type].to_s.strip
        school_id = params[:school_id].to_s.strip
        interested_role = (params[:interested_role].presence || params[:desired_role]).to_s.strip
        graduation_year = params[:graduation_year].to_s.strip

        if school_type.present? && !School::TYPES.key?(school_type)
          return render_filter_error("school_type", "学校の種類が正しくありません")
        end
        if school_id.present? && (!school_id.match?(/\A[1-9]\d*\z/) || !School.exists?(id: school_id))
          return render_filter_error("school_id", "学校名が正しくありません")
        end
        if interested_role.present? && !StudentProfile::INTERESTED_ROLE_OPTIONS.include?(interested_role)
          return render_filter_error("interested_role", "興味のある職種が正しくありません")
        end

        if graduation_year.present?
          minimum_year = Time.zone.today.year
          maximum_year = minimum_year + 2
          unless graduation_year.match?(/\A\d+\z/) && graduation_year.to_i.between?(minimum_year, maximum_year)
            return render_filter_error("graduation_year", "卒業予定年が許可範囲外です")
          end
        end

        {
          school_type: school_type,
          school_id: school_id.presence&.to_i,
          graduation_year: graduation_year.presence&.to_i,
          interested_role: interested_role
        }
      end

      def render_filter_error(field, message)
        render json: {
          errors: [{ field: field, code: "invalid", message: message }]
        }, status: :unprocessable_entity
        nil
      end

      def apply_filters(scope, filters)
        scope = scope.where(school_id: School.where(school_type: filters[:school_type])) if filters[:school_type].present?
        scope = scope.where(school_id: filters[:school_id]) if filters[:school_id]
        scope = scope.where(graduation_year: filters[:graduation_year]) if filters[:graduation_year]
        if filters[:interested_role].present?
          role_json = [filters[:interested_role]].to_json
          scope = scope.where("student_profiles.interested_roles @> ?::jsonb OR (jsonb_array_length(student_profiles.interested_roles) = 0 AND student_profiles.desired_role = ?)", role_json, filters[:interested_role])
        end
        scope
      end

      def list_item_json(profile)
        {
          id: profile.user_id,
          name: profile.name,
          school_name: profile.school_name,
          graduation_year: profile.graduation_year,
          desired_role: profile.desired_role,
          interested_roles: profile.interested_roles,
          skills: profile.skills.first(3),
          skills_count: profile.skills.length,
          self_introduction_excerpt: profile.introduction_excerpt,
          registered_at: profile.created_at.utc.iso8601
        }.merge(education_json(profile))
      end

      def detail_json(profile)
        {
          id: profile.user_id,
          name: profile.name,
          school_name: profile.school_name,
          graduation_year: profile.graduation_year,
          desired_role: profile.desired_role,
          interested_roles: profile.interested_roles,
          skills: profile.skills,
          self_introduction: profile.self_promotion.presence || profile.self_introduction,
          self_promotion: profile.self_promotion.presence || profile.self_introduction,
          student_achievement: profile.student_achievement,
          research_summary: profile.research_summary,
          english_skills: profile.english_skills,
          qualifications: profile.qualifications
        }.merge(education_json(profile))
      end

      def education_json(profile)
        { school_type: profile.school&.school_type, faculty_name: profile.faculty&.name, department_name: profile.department&.name }
      end
    end
  end
end
