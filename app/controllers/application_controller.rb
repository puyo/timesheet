class ApplicationController < ActionController::Base
  protect_from_forgery

  protected

  def basecamp_auth!
    if session[:basecamp_api_token]
      begin
        BasecampKey.auth(session[:basecamp_api_token])
      rescue
        session[:basecamp_api_token] = nil
        redirect_to edit_basecamp_key_url
      end
    else
      redirect_to edit_basecamp_key_url
    end
  end

  class BasecampError < RuntimeError
  end

  rescue_from BasecampError, :with => :basecamp_error

  def basecamp_error(error)
    logger.debug{ "Basecamp API error: #{error.message}" }
    redirect_to edit_basecamp_key_url
  end

  def basecamp_get_json(path, args = {})
    JSON.parse(basecamp(:get, path, args).body)
  end

  def basecamp_get_xml(path, args = {})
    XmlSimple.xml_in(basecamp(:get, path, args).body)
  end

  def basecamp_post(path, args = {})
    basecamp(:post, path, args)
  end

  def basecamp_put(path, args = {})
    basecamp(:put, path, args)
  end

  def basecamp_delete(path, args = {})
    basecamp(:delete, path, args)
  end

  def basecamp_get_json_async(path, args = {}, &block)
    req = basecamp(:new, path, args)
    req.on_complete do |result|
      #logger.info{ result.body }
      if result.code == 200 or result.code == 201
        block.call JSON.parse(result.body)
      else
        raise BasecampError, result.body
      end
    end
    hydra.queue req
    nil
  end

  def basecamp_get_xml_async(path, args = {}, &block)
    req = basecamp(:new, path, args)
    req.on_complete do |result|
      #logger.info{ result.body }
      if result.code == 200 or result.code == 201
        block.call XmlSimple.xml_in(result.body)
      else
        raise BasecampError, result.body
      end
    end
    hydra.queue req
    nil
  end

  def basecamp_get_json_paginated(path, args = {}, &block)
    args = args.merge(:verbose => true)
    basecamp_get_json_async(path, args) do |json|
      results = json['records']
      count = json['count']
      limit = json['limit']
      downloaded = limit
      while downloaded < count
        basecamp_get_json_async(path, args.merge(:params => {:offset => downloaded})) do |json|
          results += json['records']
        end
        downloaded += limit
      end
      basecamp_run_async
      block.call results
    end
  end

  def basecamp_run_async
    hydra.run
  end

  private

  def hydra
    @hydra ||= Typhoeus::Hydra.new
  end

  def basecamp_host
    'https://protein-one.basecamphq.com'
  end

  def typhoeus_args
    {
      :method => 'get',
      :headers => {
        'Accept' => 'application/xml',
        'Content-Type' => 'application/xml',
      },
      :timeout => 10_000, # milliseconds
      :cache_timeout => 60, # seconds
      :params => {:limit => 1_000_000},
      :verbose => false,
      :username => session[:basecamp_api_token],
      :password => 'X',
    }
  end

  def basecamp(method, path, args = {})
    actual_args = typhoeus_args.merge(args)
    actual_args[:params] = typhoeus_args[:params].merge(args[:params] || {})
    actual_args[:headers] = typhoeus_args[:headers].merge(args[:headers] || {})
    obj = Typhoeus::Request.send(method, [basecamp_host, path].join, actual_args)
    if obj.is_a?(Typhoeus::Request)
      obj
    elsif obj.code == 200 or obj.code == 201
      obj
    else
      raise BasecampError, obj.code
    end
  end
end
