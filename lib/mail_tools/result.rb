module MailTools
  class Result
    attr_accessor :message, :exit_code, :qp, :response, :method, :info

    def initialize(mail_tools_message, method, exit_code, response=nil, *info)
      self.message   = mail_tools_message
      self.exit_code = exit_code
      self.response  = response
      self.method    = method
      self.info      = info
      self.log
    end

    # Helper to check result status if you have a Result or other value
    def self.success?(result)
      result.is_a?(MailTools::Result) ? result.succeeded? : result
    end

    def succeeded?
      self.exit_code == MailTools::EXIT_OK
    end

    def deferred?
      self.exit_code == MailTools::EXIT_DEFER
    end

    def failed?
      MailTools::EXIT_ERROR.include?(self.exit_code)
    end

    def error
      self.exit_code
    end

    # "23:Kok 1182362995 qp 21894," (if it's a netstring)
    def response=(r)
      @response = r = MailTools::Netstring.decode(r||"")
      return if response.nil? || response == ""

      if m = r.to_s.match(/\A\d+:([KZD]) (.+) qp (.+)/i)
        @qp = m[3]
        self.exit_code = MailTools::DELIVERY_STATUS.fetch(m[1].downcase) { MailTools::EXIT_ERROR.first }
      end
    end

    # Returns the MailTools error message
    def error_message(code)
      "#{code}:" + (MailTools::ERRORS[code] || MailTools::EXIT_ERROR.first)
    end

    def log
      MailTools.log(:info, self.method, self.message.return_path,
                self.message.recipients.first, self.message.recipients.size,
                self.message.message.size, self.exit_code, self.response||"*",
                *self.info)
    end
  end
end
