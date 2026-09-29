class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_csrf_token
  rescue_from ActionController::ParameterMissing, with: :render_missing_parameter

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_authentication
    return if current_user

    render json: { errors: [{ field: "base", code: "unauthenticated", message: "ログインが必要です" }] }, status: :unauthorized
  end

  def require_company
    unless current_user
      render json: { errors: [{ field: "base", code: "unauthenticated", message: "ログインが必要です" }] }, status: :unauthorized
      return false
    end
    return true if current_user.company?

    render json: { errors: [{ field: "base", code: "forbidden", message: "この操作を実行する権限がありません" }] }, status: :forbidden
    false
  end

  def require_student
    unless current_user
      render json: { errors: [{ field: "base", code: "unauthenticated", message: "ログインが必要です" }] }, status: :unauthorized
      return false
    end
    return true if current_user.student?

    render json: { errors: [{ field: "base", code: "forbidden", message: "この操作を実行する権限がありません" }] }, status: :forbidden
    false
  end

  def user_json(user)
    user.as_json(only: %i[id email role])
  end

  def student_profile_json(profile)
    profile.as_json(only: %i[id user_id name last_name first_name school_id school_name faculty_id department_id graduation_year desired_role interested_roles skills self_introduction self_promotion student_achievement research_summary english_skills qualifications visible_to_companies]).merge(
      school_type: profile.school&.school_type,
      faculty_name: profile.faculty&.name,
      department_name: profile.department&.name
    )
  end

  def company_profile_json(profile)
    profile.as_json(only: %i[id user_id company_name])
  end

  def authenticated_user_json(user)
    {
      user: user_json(user),
      student_profile: user.student? ? student_profile_json(user.student_profile) : nil,
      company_profile: user.company? ? company_profile_json(user.company_profile) : nil
    }
  end

  def validation_errors(errors)
    errors.map do |error|
      field, code, fallback = if error.respond_to?(:attribute)
        [error.attribute, error.type, error.message]
      else
        error
      end

      {
        field: field.to_s,
        code: code.to_s,
        message: validation_message(field, code, fallback)
      }
    end
  end

  def validation_message(field, code, fallback)
    labels = {
      email: "メールアドレス",
      password: "パスワード",
      password_confirmation: "パスワード確認",
      name: "氏名",
      last_name: "姓",
      first_name: "名",
      school_id: "学校名",
      faculty_id: "学部・研究科",
      department_id: "学科・専攻",
      school_name: "学校名",
      graduation_year: "卒業予定年",
      desired_role: "希望職種",
      interested_roles: "興味のある職種",
      skills: "スキル",
      self_introduction: "自己紹介",
      self_promotion: "自己PR",
      student_achievement: "学生時代に力を入れたこと",
      research_summary: "研究・ゼミ内容",
      english_skills: "英語スキル",
      qualifications: "保有資格",
      company_name: "企業名",
      body: "本文",
      title: "タイトル",
      role_name: "募集職種",
      work_location: "勤務地・勤務形態",
      description: "募集内容",
      requirements: "応募条件",
      thumbnail: "サムネイル画像"
    }
    label = labels[field.to_sym] || field.to_s

    case code.to_sym
    when :blank then "#{label}を入力してください"
    when :invalid then "#{label}が正しくありません"
    when :taken then "#{label}はすでに使用されています"
    when :confirmation then "#{label}がパスワードと一致しません"
    when :too_short then "#{label}は8文字以上で入力してください"
    when :too_long then "#{label}が上限文字数を超えています"
    when :too_many then "#{label}が上限件数を超えています"
    when :too_large then "#{label}は5MB以下にしてください"
    when :greater_than_or_equal_to, :less_than_or_equal_to then "#{label}が許可範囲外です"
    when :not_a_number, :not_an_integer then "#{label}は整数で入力してください"
    else fallback
    end
  end

  def render_invalid_csrf_token
    render json: { errors: [{ field: "csrf_token", code: "invalid", message: "CSRFトークンが無効です" }] }, status: :unprocessable_entity
  end

  def render_missing_parameter(error)
    render json: {
      errors: [{ field: error.param.to_s, code: "missing", message: "必要な入力データがありません" }]
    }, status: :unprocessable_entity
  end
end
