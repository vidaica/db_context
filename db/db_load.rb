require 'active_record'
require 'fileutils'
require 'logger'

config_file = File.open( File.join( File.dirname(__FILE__), 'config.yml') )
ActiveRecord::Base.establish_connection( YAML::load( config_file )['development'] )

log_file = File.join( File.dirname(__FILE__), 'log', 'database.log' )
FileUtils.mkdir_p File.dirname(log_file)
ActiveRecord::Base.logger = Logger.new( File.open log_file , 'w')

require File.dirname(__FILE__) + '/models/father.rb'
require File.dirname(__FILE__) + '/models/child.rb'

