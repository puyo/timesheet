class TodoItemsController < ApplicationController
  before_filter :basecamp_auth!

  respond_to :json

  def index
    args = {
      :method => 'get',
      :headers => {
        'Accept' => 'application/xml',
        'Content-Type' => 'application/xml',
      },
      :timeout => 5_000, # milliseconds
      :cache_timeout => 60, # seconds
      :params => {:limit => 1_000_000},
      :verbose => false,
      :username => session[:basecamp_api_token],
      :password => 'X',
    }
    hydra = Typhoeus::Hydra.new
    lists = JSON.parse(Typhoeus::Request.get("https://protein-one.basecamphq.com/projects/#{params[:project_id]}/todo_lists.json", args).body)['records']
    result = []
    lists.each do |list|
      time_entries_request = Typhoeus::Request.new("https://protein-one.basecamphq.com/todo_lists/#{list['id']}/todo_items.json", args)
      hydra.queue time_entries_request
      time_entries_request.on_complete do |response|
        #list['entries'] = JSON.parse(response.body)['records']
        result += JSON.parse(response.body)['records']
      end
    end
    hydra.run
    respond_with result
  end

  def show
    respond_with Basecamp::TodoItem.find(params[:id])
  end
end
