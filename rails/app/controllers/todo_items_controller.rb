class TodoItemsController < ApplicationController
  before_filter :basecamp_auth!

  respond_to :json

  # GET /todo_items/1.json
  def show
    respond_with Basecamp::TodoItem.find(params[:id])
  end
end
