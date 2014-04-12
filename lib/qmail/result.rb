module Qmail
  class Result
    attr_accessor :message, :exit_code, :qp, :response, :method, :info

    def initialize(qmail_message, method, exit_code, response=nil, *info)
      self.message   = qmail_message
      self.exit_code = exit_code
      self.response  = response
      self.method    = method
      self.info      = info
      self.log
    end

    # Helper to check result status if you have a Result or other value
    def self.success?(result)
      result.is_a?(Qmail::Result) ? result.success? : result
    end

    def succeeded?
      @exit_code == Qmail::EXIT_OK
    end

    def deferred?
      @exit_code == Qmail::EXIT_DEFER
    end

    def failed?
      Qmail::EXIT_ERROR.include?(@exit_code)
    end

    def error
      @exit_code
    end

    # "23:Kok 1182362995 qp 21894," (if it's a netstring)
    def response=(r)
      @response = r = Qmail::Netstring.value(r||"")
      return if response.nil? || response == ""

      if m = r.match(/\A\d+:([KZD]) (.+) qp (.+)/i)
        @qp = m[3]
        @exit_code = Qmail::DELIVERY_STATUS.fetch(m[1].downcase) { Qmail::EXIT_ERROR.first }
      end
    end

    # Returns the Qmail error message
    def error_message(code)
      "#{code}:" + (Qmail::ERRORS[code] || Qmail::EXIT_ERROR.first)
    end

    def log
      Qmail.log(:info, self.method, self.message.return_path,
                self.message.recipients.first, self.message.recipients.size,
                self.message.message.size, self.exit_code, self.response||"*",
                *self.info)
    end
  end
end
