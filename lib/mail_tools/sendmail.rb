module MailTools

  # Implements the basic Sendmail command line to send email
  #
  #     echo message | sendmail -f return_path recipients ...
  #
  # If return path or recipients are not provided, they are taken
  # from the message
  #
  # To use this way, invoke this command from the command line or shell script:
  #
  #     echo message | ruby -r mail_tools -e 'MailTools.command' -- -f return_path recipients...
  #
  # You may also pass in mail_tools message sending options:
  #   --method=queue|qmqp|smtp|maildrop|http|mailbox|maildir
  #   --ip=ipv4
  #   --port=integer
  #   --maildrop-dir=dirname
  #   --mail_tools-queue=filename
  #   --mail_tools-root/dirname
  #   --http-url=url
  #   --mailbox=filepath
  #   --maildir=dirname
  #  # To use a shell script, you can also send options with default delivery method
  #
  # sendmail.sh:
  #     ruby -r mail_tools -e 'MailTools.command(method: :queue)' -- $*
  #
  class Sendmail
    def self.command(options={})
      options, recipients = command_arguments(options)
      options[:mailhandle] ||= $stdin
      options[:f] ||= default_return_path
      qmessage = MailTools::Message.new('', options[:f], recipients, options)
      qmessage.use_headers(false) # Only replace missing return_path, recipients

      qmessage.sendmail
    end

    def self.command_arguments(options={})
      GetoptLong.new(
        ['-f',                  GetoptLong::REQUIRED_ARGUMENT], # from (return_path)
        ['--method',            GetoptLong::REQUIRED_ARGUMENT], # Options to MailTools::Message
        ['--ip',                GetoptLong::REQUIRED_ARGUMENT], #  " "
        ['--port',              GetoptLong::REQUIRED_ARGUMENT],
        ['--maildrop-dir',      GetoptLong::REQUIRED_ARGUMENT],
        ['--mail_tools-queue',  GetoptLong::REQUIRED_ARGUMENT],
        ['--mail_tools-root',   GetoptLong::REQUIRED_ARGUMENT],
        ['--http-url',          GetoptLong::REQUIRED_ARGUMENT],
        ['--mailbox',           GetoptLong::REQUIRED_ARGUMENT],
        ['--maildir',           GetoptLong::REQUIRED_ARGUMENT],
        ['--mail_toolsrc',      GetoptLong::REQUIRED_ARGUMENT],
      ).each {|opt, arg| options[opt.sub(/\A-+/,'').gsub(/\W/,'_').to_sym] =  arg }
      recipients = ARGV
      options = load_mail_toolsrc(options)

      [options, recipients]
    end

    def self.default_return_path
      (ENV['USER']||ENV['USERNAME']) + '@' + Socket.gethostname
    end

    def self.load_mail_toolsrc(options)
      fn = options[:mail_toolsrc] || "#{ENV["HOME"]}/.mail_toolsrc"
      return options unless File.exists?(fn)
      yaml = YAML.load_file(fn)
      yaml.merge(options)
    end

    def self.deliver(msg)
      
    end

    def deliver(msg)
      
    end
  end
end
