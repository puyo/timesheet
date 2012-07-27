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
      if result.code == 200
        block.call JSON.parse(result.body)
      else
        raise BasecampError, result.body
      end
    end
    req
  end

  def basecamp_get_xml_async(path, args = {}, &block)
    req = basecamp(:new, path, args)
    req.on_complete do |result|
      if result.success?
        block.call XmlSimple.xml_in(result.body)
      else
        raise BasecampError, result.body
      end
    end
    req
  end

  private

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
    obj = Typhoeus::Request.send(method, [basecamp_host, path].join, typhoeus_args.merge(args))
    if obj.is_a?(Typhoeus::Request)
      obj
    elsif obj.code == 200 or obj.code == 201
      obj
    else
      raise BasecampError, obj.code
    end
  end
end
