require "bundler/gem_tasks"
require "bundler/gem_tasks"
require "bundler/setup"
require 'rake/testtask'

task :default => :test

desc "Run the Test Suite, toot suite"
task :test do
  #t.test_files = FileList["test/mailtools/test*.rb"]
  #sh "ruby test/mail_tools/test_*"
  sh "find test -name 'test*.rb' -exec ruby {} \\;"
end

desc "Open and IRB Console with the gem"
task :console do
  sh "bundle exec irb  -Ilib -I . -r mail_tools"
end

