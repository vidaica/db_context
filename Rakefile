require "bundler/gem_tasks"
require 'rake/testtask'

require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks
 
Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.test_files = FileList['test/lib/*_test.rb']
  t.verbose = true
end
 
task :default => :test