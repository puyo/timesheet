require 'basecamp'

module Basecamp
  class TimeEntry < Basecamp::Resource
    # Specifying this seems to prevent data being returned in each resource
    # object, but I'd rather have that data. I am not sure how else to access
    # it from ActiveResource, unless it is put in each resource object.
    parent_resources []
  end
end
