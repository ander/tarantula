source "http://rubygems.org"

gem 'rails', '3.2.6'
gem 'mysql'
gem 'prawn', '~> 0.5.0.1'
gem 'prawn-core', '~> 0.5.0.1', :require => 'prawn/core'
gem 'prawn-layout', '~> 0.2.0.1', :require => 'prawn/layout'
gem 'prawn-format', '~> 0.2.0.1', :require => 'prawn/format'
gem 'spreadsheet', '~> 0.6.5'
gem 'libxml-ruby', :require => 'libxml_ruby'
gem 'faker'
gem 'json'
gem 'rake'
gem 'jquery-rails'
gem "therubyracer"
gem 'delayed_job_active_record'
gem 'memcache-client'
gem 'rb-readline'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

#group :development do
#  gem 'ruby-debug19'
#end

group :test do
  gem "flexmock"
  gem 'machinist', '>= 2.0.0.beta2'
  gem 'test-unit', '~> 1.2.3'
end

group :production do
  gem 'passenger'
end

group :test, :development do
  gem "rspec-rails", "~> 2.0"
end
