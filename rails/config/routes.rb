Timesheet::Application.routes.draw do
  resource :basecamp_key, :only => [:edit, :update]
  root :to => 'timesheet#show'
end
