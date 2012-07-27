class TodoItemsController < ApplicationController
  before_filter :basecamp_auth!

  respond_to :json

  def index
    lists = basecamp_get_json("/projects/#{params[:project_id]}/todo_lists.json")['records']
    result = []
    lists.each do |list|
      basecamp_get_json_async("/todo_lists/#{list['id']}/todo_items.json") do |json|
        result += json['records']
      end
    end
    basecamp_run_async
    respond_with result
  end

  def show
    respond_with Basecamp::TodoItem.find(params[:id])
  end
end
