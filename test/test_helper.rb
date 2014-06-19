require 'rubygems'
require 'minitest/autorun'
require 'minitest/pride'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'qmail'

def basic_email
  "Subject: Testing\nFrom: <me@example.com>\nTo: <you@example.com>\n\nTest Me!"
end

def basic_message(from=ENV['FROM'], to=ENV['TO'], opt={})
  Qmail::Message.new(basic_email, from||'me@example.com', to||'you@example.com',
                     {method: :queue}.merge(opt))
end

MAILDROP_DIR = "/tmp/qmail-ruby-maildrop"

def maildrop
  Dir.mkdir(MAILDROP_DIR) unless Dir.exist?(MAILDROP_DIR)
  Qmail::Maildrop.new(MAILDROP_DIR)
end
