Timesheet::Application.routes.draw do
  resources :projects, :only => [:index, :show] do
    resources :todo_items, :only => [:index, :show]
  end
  resources :time_entries
  resource :basecamp_key, :only => [:edit, :update]
  root :to => 'time_entries#index'
end
