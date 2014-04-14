#!/bin/env/ruby 
################################################################################
# Ruby implementation of qmail-queue interface
#
# 1) Read message body from FD 0 (stdin) until EOF
# 2) Read Envelope from Fd 1 (STDOUT)
#    F + return_path +  "\0"
#    T + return_path +  "\0" ...
#    "\0"
# 3) Exit with Qmail::EXIT_OK or Qmail::ERRORS[errno]
################################################################################
require 'rubygems'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'qmail'

dbug = File.new("debug", 'w');
dbug.puts "Starting..."
qmsg = Qmail::Message.new
qmsg.message = IO.new(0, 'r').read
dbug.puts "Message...", qmsg.message
env = IO.new(1, 'r')
qmsg.return_path = env.gets("\0")
dbug.puts "RPATH...", qmsg.return_path
while recip = qmsg.return_path = env.gets("\0") && recip > " "
  qmsg.recipients << recip
  dbug.puts "recip...", qmsg.recipients
end
dbug.puts qmsg.to_s
exit qmsg.message =~ /Subject/ && qmsg.return_path =~ /@/ ? Qmail::QMAIL_OK : Qmail::ERRORS[1]
