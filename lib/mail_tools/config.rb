module MailTools

  # MailTools::Config - Stores and Retries Configuration Settings
  # Usage:
  #   MailTools::Config.setting = "value"
  #   do_somthing() if MailTools::Config.setting == "value"
  class Config
    @options = {
      qmail: {
        dir:         "/var/qmail",
        queue:       "/var/qmail/bin/qmail-queue",
        qmqp_server: "localhost",
        qmqp_port:   628,
      },
      smtp: {
        host:        "localhost",
        port:        25,
        user:        ENV['SMTP_USER'],
        password:    ENV['SMTP_PASSWORD'],
        threads:     10,
      },
      sendmail: {},
      maildrop: {},
      maildir: {},
      mailbox: {},
      http: {},
    }

    def self.options
      @options
    end

    def self.setup
      instance_eval ### In progress
    end

    def self.method_missing(method, *args, &block)
      if args.size>0
        method = method.to_s.chop.to_sym if method.to_s =~ /=\z/
        @options[method] = args.first
      else
        @options[method]
      end
    end
  end
end
