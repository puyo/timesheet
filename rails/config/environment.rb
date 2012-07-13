# Load the rails application
require File.expand_path('../application', __FILE__)

ActiveResource::Base.logger = ActiveRecord::Base.logger

# Initialize the rails application
Timesheet::Application.initialize!
