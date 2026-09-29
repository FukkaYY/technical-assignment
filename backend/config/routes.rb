Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      get "csrf", to: "csrf#show"
      get "education_options", to: "education_options#index"
      post "student_registrations", to: "student_registrations#create"
      post "session", to: "sessions#create"
      get "me", to: "sessions#show"
      delete "session", to: "sessions#destroy"
      resource :student_profile, only: :update
      patch "student_profile/visibility", to: "student_profiles#update_visibility"
      resources :students, only: %i[index show] do
        resources :messages, only: %i[index create], controller: :student_messages
        resources :schedule_proposals, only: :create, controller: :company_schedule_proposals
      end
      resources :conversations, only: %i[index show] do
        patch :read, on: :member, action: :mark_read
        patch :schedule_proposals_seen, on: :member, action: :mark_schedule_proposals_seen
        resources :messages, only: :create, controller: :conversation_messages
      end
      resources :job_postings, only: %i[index show] do
        get :thumbnail, on: :member
      end
      post "job_postings/:id/interest", to: "job_postings#interest"
      delete "job_postings/:id/interest", to: "job_postings#destroy_interest"
      namespace :company do
        resources :conversations, only: :index
        resources :job_postings, only: %i[index show create update] do
          patch :close, on: :member
        end
      end
      patch "company/schedule_proposals/:id/cancel", to: "company_schedule_proposals#cancel"
      patch "schedule_proposals/:id/accept", to: "student_schedule_proposals#accept"
      patch "schedule_proposals/:id/decline", to: "student_schedule_proposals#decline"
    end
  end
end
