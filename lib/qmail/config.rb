module Qmail

  # Qmail::Config - Stores and Retries Configuration Settings
  # Usage:
  #   Qmail::Config.setting = "value"
  #   do_somthing() if Qmail::Config.setting == "value"
  class Config
    @options = {
      qmail_dir:   "/var/qmail",
      qmail_queue: "/var/qmail/bin/qmail-queue",
      qmqp_port:   628,
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
