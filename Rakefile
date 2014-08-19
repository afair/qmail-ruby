require "bundler/gem_tasks"
require "bundler/gem_tasks"
require "bundler/setup"
require 'rake/testtask'

task :default => :test

desc "Run the Test Suite, toot suite"
task :test do
  sh "ruby test/mail_tools/test_*"
end

desc "Open and IRB Console with the gem"
task :console do
  sh "bundle exec irb  -Ilib -I . -r mail_tools"
end

