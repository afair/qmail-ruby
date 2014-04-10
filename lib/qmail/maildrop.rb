module Qmail

  # The Maildrop and Mailfile constructs do not come from Qmail, and are
  # provided as a simple service to avoid network issues and gives emails
  # a place to stay before retrying after an unsuccessful send. It can
  # also replace a message queue or separate publisher and email functionality.
  #
  # A Maildrop is a directory to which Qmail::Message files are serialized
  # and named with the MD5 digest of the message data and envelope. With
  # this approach, identical messages could be overwritten.
  #
  # The mailfile is of the format:
  #    Mailfile --option=value ....               [Optional]
  #    returnpath@example.com
  #    recipient1@example.com                     [Recipients, 1 per line]
  #    ...
  #                                               [Blank line]
  #    Message Data (RFC822 Headers and Bodies)
  #
  class Maildrop
    
    def self.sendmail(qmail_message, dir)
      Qmail::Maildrop.new(dir).sendfile(qmail_message)
    end

    def initialize(dir)
      raise "Qmail::Maildrop directory #{dir} does not exist" unless Dir.exists?(dir)
      @dir = dir
    end

    def sendmail(qmail_message)
      filename = qmail_message.to_md5
      qmail_message.save_mailfile(dir + File::SEPARATOR + filename)
    end

    # Iterates through the maildrop directory, returning a Qmail::Message
    # object and filename (if you want to stat it) to the block. The
    # block should return a true value on successful processing to delete
    # the Mailfile from the Maildrop, or false to keep the file to retry later.
    #
    # Example Usage:
    #   Qmail::Maildrop.new(dir).pickup {|m| m.sendmail }
    #
    def pickup
      Dir.new(@dir).each do |filename|
        if filename =~ /\A\w/ # Not a . or .. 
          path = @dir + File::SEPARATOR + filename
          m = Qmail::Maildrop.mailfile(path)

          if yield m, path
            File.unlink path
          else
            if m = filename.match(/\A(\w+)\.(\d+)\z/)
              newpath = @dir + File::SEPARATOR + m[1] + '.' + (m[2].to_i + 1)
            else
              newpath = @dir + File::SEPARATOR + filename + '.1'
            end
            File.rename(path, newpath)
          end
        end
      end
    end

    # Loads message from a Mailfile
    def self.mailfile(filename)
      msg = Qmail::Message.new
      File.open(filename) do |f|
        while (rec = f.readline.chomp) > ""
          if rec =~ /\AMailfile (.+)/
            msg.options = parse_options($1)
          elsif msg.return_path.nil?
            msg.return_path = rec
          else
            msg.recipients.push(rec)
          end
        end
        msg.message = f.read
      end
      msg
    end

    def save_mailfile(msg, filename)
      header = ""
      msg.options.each { |k,v| header += "--#{k}=#{v} " }
      File.open(filename,'w') do |f|
        f.puts "Mailfile #{header.strip}" if header > ""
        f.puts msg.return_path
        msg.recipients.each { |r| f.puts r }
        f.puts "\n" + msg.message
      end
    end

    # Parses "--option=value" formats, puts in options
    def parse_options(str)
      opts = {}
      while m = str.match(/\A\s*--(\w+)[=\s]+(.+?)(\s*--.+)?/)
        self.options[m[1].to_sym] = m[2]
        str = m[3]
      end
      opts
    end

  end
end
