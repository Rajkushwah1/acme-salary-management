Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resource :session, only: [:create, :show, :destroy]
      resources :employees, only: [:index, :show, :create, :update] do
        member do
          post :deactivate
        end
        resources :salaries, only: [:index] do
          collection do
            post :revise
          end
        end
      end
      resources :salaries, only: [] do
        member do
          patch :correct
        end
      end
      resources :audit_logs, only: [:index]
      get "analytics/summary", to: "analytics#summary"
      get "analytics/breakdown", to: "analytics#breakdown"
      get "meta", to: "meta#index"
    end
  end
end
