Timesheet::Application.routes.draw do
  resources :basecamp_projects do
    collection do
      post 'refresh'
    end
  end
  resources :projects do
    resources :todo_items, :only => [:index, :show]
    collection do
      post 'measure'
    end
  end
  resources :time_entries
  resource :basecamp_key, :only => [:edit, :update]
  root :to => 'time_entries#index'
end
