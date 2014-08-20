require 'socket'
require 'fileutils'

module MailTools

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

    def self.deliver(mail_tools_message, dir)
      MailTools::Maildir.new(dir).deliver(mail_tools_message)
    end

    def self.create(dir)
      FileUtils.mkdir_p(File.join(dir,'cur'))
      %w(tmp new).each {|w| Dir.mkdir(File.join(dir,w)) }
      Maildir.new(dir)
    end

    def clean!
      kill!
      Maildir.create(@dir)
      self
    end

    def kill!
      FileUtils.rmtree(@dir)
    end

    def initialize(dir)
      @dir = dir
    end

    # Adds message to maildir. First, we write to dir/tmp/uniquename, then move to 
    # dir/new for MUA to receive.
    # Returns filename of message
    def deliver(msg)
      fname = nil
      loop do
        fname = [Time.now.to_i, rand(99999), Socket.gethostname].join('.')
        break unless File.exists?(File.join(@dir, 'new', fname))
      end
      File.open(File.join(@dir, 'tmp', fname), 'w') do |f|
        f.puts "Return-Path: <#{msg.return_path}>"
        msg.recipients.each { |recip| f.puts "Delivered-To: #{recip}" }
        f.puts msg.message
      end
      File.rename(File.join(@dir, 'tmp', fname), File.join(@dir, 'new', fname))
      File.join(@dir, 'new', fname)
    end

    # Yields each new message with Message and Filename
    def receive
      Dir.new(File.join(@dir,'new')).each do |filename|
        if filename =~ /\A\w/ # Not a . or .. 
          n = File.join(@dir, 'new', filename)
          c = n.sub('/new/', '/cur/')
          c += ':2,'
          File.rename(n, c)
          m = MailTools::Message.read(c)
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
          n = MailTools::Message.read(f)
          yield f, n
        end
      end
    end

  end
end
