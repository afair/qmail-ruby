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
      Qmail::Maildrop.new(dir).sendmail(qmail_message)
    end

    def initialize(dir)
      dir ||= ENV['MAILDROP_DIR']
      raise "Qmail::Maildrop directory #{dir} does not exist" if !dir || !Dir.exists?(dir)
      @dir = dir
    end

    def sendmail(qmail_message)
      filename = @dir + File::SEPARATOR + qmail_message.to_md5
      rc = save_mailfile(qmail_message, filename)
      filename = rename_to_inode(filename) if Qmail::Config.maildrop_inode
      Qmail::Result.new(qmail_message, :maildrop, rc, nil, filename)
    end

    # Iterates through the maildrop directory, returning a Qmail::Message
    # object and filename (if you want to stat it) to the block. The
    # block should return a true value on successful processing to delete
    # the Mailfile from the Maildrop, or false to keep the file to retry later.
    #
    # Example Usage:
    #   Qmail::Maildrop.new(dir).pickup {|m| Qmail::Inject.sendmail(m) }
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

    # Loads message from a Mailfile, returns a Qmail::Message object
    def self.mailfile(filename)
      msg = Qmail::Message.new
      File.open(filename) do |f|
        while (rec = f.readline.chomp) > ""
          if rec =~ /\AMailfile (.+)/
            msg.options = parse_options($1)
          elsif msg.return_path.nil? || msg.return_path == ""
            msg.return_path = rec
          else
            msg.recipients.push(rec)
          end
        end
        msg.message = f.read.chomp
      end
      msg
    end

    # Takes a Qmail::Message and a target path and filename. Serializes the
    # message to the given filename
    def save_mailfile(msg, filename)
      begin
        header = option_string(msg.options) unless msg.options.empty?
        File.open(filename,'w') do |f|
          f.puts header if header
          f.puts msg.return_path
          msg.recipients.each { |r| f.puts r }
          f.puts "\n" + msg.message
        end
      rescue
      end
      File.exist?(filename) ? Qmail::EXIT_OK : Qmail::ERRORS[53]
    end

    private

    def option_string(options)
      header = ""
      options.each { |k,v| header += "--#{k}=#{v} " }
      header > "" ? "Mailfile #{header.strip}" : ""
    end

    # Parses "--option=value" formats, puts in options
    def self.parse_options(str)
      opts = {}
      while str && m = str.match(/\A\s*--(\w+)[=\s]+(\S+)/)
        opts[m[1].to_sym] = m[2]
        str = m[3]
      end
      opts
    end

    # Renames file to the inode number, like qmail does in it's queue
    # Enable this if you want to keep identical messages separate.
    def rename_to_inode(filename)
      st = File::Stat.new(filename)
      newname = @dir + File::SEPARATOR + st.ino.to_s
      File.rename(filename, @dir + File::SEPARATOR + st.ino.to_s)
      newname
    end

  end
end
