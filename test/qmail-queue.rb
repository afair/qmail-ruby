#!/bin/env/ruby
################################################################################
# Ruby implementation of qmail-queue interface
#
# 1) Read message body from FD 0 (STDIN) until EOF
# 2) Read Envelope from Fd 1 (remapped from STDOUT)
#    F + return_path +  "\0"
#    T + return_path +  "\0" ...
#    "\0"
# 3) Exit with Qmail::EXIT_OK or Qmail::ERRORS[errno]
################################################################################
require 'rubygems'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'qmail'

begin
  dbug = File.new("debug", 'w')
  dbug.sync = true
  qmsg = Qmail::Message.new
  dbug.puts "Starting..."

  dbug.puts "Message..."
  msg_fd = IO.new(0, 'r')
  dbug.puts "Message..."
  qmsg.message = msg_fd.read
  dbug.puts qmsg.message

  env = IO.new(1, 'r')

  dbug.puts "RPATH..."
  qmsg.return_path = env.gets("\0")
  dbug.puts qmsg.return_path

  dbug.puts "RECIP..."
  while recip = qmsg.return_path = env.gets("\0") && recip > " "
    qmsg.recipients << recip
    dbug.puts qmsg.recipients.last
  end

  dbug.puts qmsg.to_s

rescue Exception => e
  dbug.puts "ERROR!!!"
  dbug.puts e.inspect if dbug

ensure
  dbug.puts "DONE!!!"

end




exit qmsg.message =~ /Subject/ && qmsg.return_path =~ /@/ ? Qmail::QMAIL_OK : Qmail::ERRORS[1]
