source 'https://rubygems.org'

gem 'rails', '~> 3.2.3'

gem 'basecamp'
gem 'compass-rails'
gem 'compass_twitter_bootstrap'
gem 'haml-rails'
gem 'jquery-rails'
gem 'typhoeus'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem 'ruby-debug', :require => nil
end

group :development do
  gem 'capistrano'
  gem 'capistrano_colors'
  gem 'guard-rspec'
  gem 'guard-livereload'
  gem 'rb-fsevent'
  gem 'hpricot'
  gem 'erubis'
  gem 'ruby_parser'
end

group :test do
  gem 'capybara'
  gem 'machinist'
  gem 'bcat'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'timecop'
end

group :test, :development do
  gem 'rspec-rails'
  gem 'shoulda-matchers'
end

# vim: ft=ruby
