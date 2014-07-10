require 'db_context'
require 'rspec'
require 'database_cleaner'
require_relative './matchers'

require File.join( File.dirname(__FILE__), '..', 'db', 'db_load' ) #load model classes

FactoryGirl.find_definitions

RSpec.configure do |config|
  
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction    
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end