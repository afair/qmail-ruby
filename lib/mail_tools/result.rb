require 'securerandom'

module MailTools
  class Result
    attr_accessor :id, :timestamp, :message, :exit_code, :qp, :response, :method, :info

    def initialize(mail_tools_message, method, exit_code, response=nil, *info)
      self.id        = SecureRandom.uuid
      self.timestamp = Time.new
      self.message   = mail_tools_message
      self.exit_code = exit_code
      self.response  = response
      self.method    = method
      self.info      = info
      self.log
    end

    def to_hash
      { request_id:      self.id,
        timestamp:       self.timestamp,
        return_path:     self.message.return_path,
        recipients:      self.message.recipients.count,
        first_recipient: self.message.recipients.first,
        size:            self.message.message.size,
        subject:         self.message.header(:subject),
        success:         self.exit_code == 0 ? 1 : 0,
        response:        self.response,
        method:          self.method,
      }
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
      @raw_response = r
      @response = MailTools::Netstring.decode(r||"")
      @response = @response.first if @response.is_a?(Array)
      return @response if @response.nil? || @response == ""

      # Kok 1412877119 qp 44150
      if m = r.to_s.match(/\A([KZD])\S+ (.+) qp (.+)/i)
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
