Timesheet::Application.routes.draw do
  resources :todo_items, :only => [:show]
  resources :projects, :only => [:show]

  resource :basecamp_key, :only => [:edit, :update]
  root :to => 'timesheet#show'
end
