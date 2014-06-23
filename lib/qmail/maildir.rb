require 'socket'

module Qmail

  # Delivers a Message to a Maildir format directory. See:
  #   http://en.wikipedia.org/wiki/Maildir
  # This is better for dropping messages in NFS, or shared file systems
  # having locking issues, or where you don't want to wait for a lock
  #
  # Maildirs usage and file flow:
  #   ~/Maildir/tmp/<unique>     #=> Writes msg here to prevent early detection
  #   ~/Maildir/new/<unique>     #=> Moves new msg here once writing completes
  #   ~/Maildir/cur/<unique>:2,<flags>  #=> MUA moves msg here with flags
  #
  class Maildir
    include Enumerable

    INFO = {'P'=>'Passed/Resent/Forwarded/Bounced', 'R'=>'Replied', 'S'=>'Seen',
            'T'=>'Trashed', 'D'=>'Draft', 'F'=>'Flagged'}

    def self.sendmail(qmail_message, dir)
      Qmail::Maildir.new(dir).sendmail(qmail_message)
    end

    def initialize(dir)
      @dir = dir
    end

    def sendmail(qmail_message)
      write_message(qmail_message)
    end

    # Adds message to maildir. First, we write to dir/tmp/uniquename, then move to 
    # dir/new for MUA to pickup.
    def write_message(msg)
      until !File.exists?(File.join(@dir, 'new', fname))
        fname = [Time.now.to_i, rand(99999), Socket.gethostname].join('.')
      end
      File.open(File.join(@dir, 'tmp', fname)) do |f|
        f.puts "Return-Path: <#{msg.return_path}>"
        msg.recipients.each { |recip| f.puts "Delivered-To: <#{recip}>" }
        f.puts msg.message
      end
      File.rename(File.join(@dir, 'tmp', fname), File.join(@dir, 'new', fname))
    end

    # Yields each new message with Message and Filename
    def pickup
      Dir.new(File.join(@dir,'new')).each do |filename|
        if filename =~ /\A\w/ # Not a . or .. 
          n = File.join(@dir, filename)
          c = n.sub('/new/', '/cur/')
          c += ':2,'
          File.rename(n, c)
          m = Qmail::Message.read(c)
          yield m, c
        end
      end
    end

    # Iterates over each message in the "cur" messages.
    # Returns the Message and filename for each
    def each
      Dir.new(File.join(@dir,'cur')).each do |filename|
        if filename =~ /\A\w/ # Not a . or .. 
          f = File.join(@dir, filename)
          n = Qmail::Message.read(f)
          yield f, n
        end
      end
    end

  end
end
