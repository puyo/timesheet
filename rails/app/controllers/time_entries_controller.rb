class TimeEntriesController < ApplicationController
  #before_filter :basecamp_auth!
  respond_to :js

  def create
    #new_req = Typhoeus::Request.get("https://protein-one.basecamphq.com/projects/#{project_id}/time_entries/new.xml", typhoeus_args.merge(:verbose => true))
    #puts new_req.body
    req = Typhoeus::Request.post("https://protein-one.basecamphq.com/projects/#{project_id}/time_entries.xml", typhoeus_args.merge({
      :verbose => true,
      :body => xml,
    }))
    render :text => 'hi', :status => req.code
  end

  def update
    req = Typhoeus::Request.put("https://protein-one.basecamphq.com/time_entries/#{params[:id]}.xml", typhoeus_args.merge({
      :verbose => true,
      :body => xml,
    }))
    render :text => 'hi', :status => req.code
  end

  def destroy
    req = Typhoeus::Request.delete("https://protein-one.basecamphq.com/time_entries/#{params[:id]}.xml", typhoeus_args.merge({
      :verbose => true,
    }))
    if req.code == 200
      @id = params[:id]
    end
  end
  
  private

  def project_id
    params[:time_entry][:project_id]
  end

  def xml
    ps = params[:time_entry]
    entry = <<-ENTRY
    <time-entry>
      <date nil="true">#{ps[:date]}</date>
      <description nil="true">#{ps[:description]}</description>
      <hours type="float">#{ps[:hours]}</hours>
      <person-id nil="true">#{ps[:person_id]}</person-id>
    </time-entry>
    ENTRY
  end
end
