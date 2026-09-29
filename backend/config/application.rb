require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module TechnicalAssignment
  class Application < Rails::Application
    config.load_defaults 8.1
    config.api_only = true
    config.cache_store = :memory_store, { size: 16 * 1024 * 1024 }

    # APIモードでもCookieセッションを利用するため、必要なmiddlewareだけを戻す。
    config.session_store :cookie_store,
      key: "_technical_assignment_session",
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options
  end
end
