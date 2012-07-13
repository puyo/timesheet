Timesheet::Application.routes.draw do
  resources :projects

  resource :basecamp_key, :only => [:edit, :update]
  root :to => 'timesheet#show'
end
