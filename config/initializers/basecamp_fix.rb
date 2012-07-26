require 'basecamp'

module Basecamp
  # Specifying this seems to prevent data being returned in each resource
  # object, but I'd rather have that data. I am not sure how else to access
  # it from ActiveResource, unless it is put in each resource object.
  class TimeEntry < Basecamp::Resource
    parent_resources []
  end
  class Person < Basecamp::Resource
    parent_resources []
  end
end
