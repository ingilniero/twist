# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'sidekiq/testing'
Sidekiq::Testing.inline!

require 'capybara/poltergeist'
Capybara.app_host = "http://lvh.me"
Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.mock_with :rspec


  config.before do
    ActionMailer::Base.deliveries.clear
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with :truncation, except: %w(ar_internal_metadata)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
      Apartment::Tenant.reset

      connection = ActiveRecord::Base.connection.raw_connection
      schemas = connection.query(%Q{
        SELECT
          'drop schema "' || nspname || '" cascade;'
        FROM
          pg_namespace
        WHERE
          nspname != 'public' AND
          nspname NOT LIKE 'pg_%' AND
          nspname != 'information_schema';
      })

      schemas.each do |query|
        connection.query(query.values.first)
      end
    end
  end

  config.filter_gems_from_backtrace(
    "actionpack",
    "actionview",
    "activerecord",
    "activesupport",
    "capybara",
    "rack",
    "rack-test",
    "railties",
    "request_store",
    "warden",
    "zeus"
  )

  config.infer_spec_type_from_file_location!

  config.include Warden::Test::Helpers, type: :feature
end
