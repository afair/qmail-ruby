module Qmail

  # The Qmail::Inject class inserts a message into the queue
  class Inject
    attr_accessor :message, :return_path, :recipients, :options

    # Single-step processor
    def self.queue(message, return_path, recipients, options={})
      inject = Qmail::Inject.new(message, return_path, recipients, options)
      inject.sendmail
    end

    def initialize(message, return_path, recipients, options={})
      self.message     = message
      self.return_path = return_path
      self.recipients  = recipients
      self.options     = options

      self.mailfile(options[:mailfile])             if options[:mailfile]
      self.recipient_file(options[:recipient_file]) if options[:recipient_file]
    end

    # Loads message in Mailfile format
    def mailfile(filename)
      File.open(filename) do |f|
        while (rec = f.readline.chomp) > ""
          if rec =~ /\AMailfile (.+)/
            parse_options
          elsif self.return_path.nil? or self.return_path == ""
            self.return_path = rec
          else
            self.recipients.push(rec)
          end
        end
        self.message = f.read
      end
    end

    # Parses "--option=value" formats, puts in options
    def parse_options(str)
      while m = str.match(/\A\s*--(\w+)[=\s]+(.+?)(--.+)?/)
        self.options[m[1].to_sym] = m[2]
        str = m[3]
      end
    end

    def recipient_file(filename)
      File.readlines(filename).each do |rec|
        self.recipients.push($1) if rec =~ /\A\s*(\S+@\S)/
      end
    end

  end
end
