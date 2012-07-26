class BasecampKey
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  validates_presence_of :basecamp_api_token

  def initialize(session)
    @session = session
  end

  def basecamp_api_token
    @session[:basecamp_api_token]
  end

  def basecamp_api_token=(value)
    @session[:basecamp_api_token] = value
  end

  def persisted?
    false
  end

  def self.auth(token)
    Basecamp.establish_connection!('protein-one.basecamphq.com', token, 'X', true)
  end
end
