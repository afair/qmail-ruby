require 'net/http'

module MailTools
  class HTTP

    def self.sendmail(mail_tools_message, url)
      MailTools::HTTP.new(mail_tools_message, url).sendmail
    end

    def initialize(mail_tools_message, url=nil, http_lib=Net::HTTP)
      @qmsg     = mail_tools_message
      @url      = url || @qmsg.options[:http_url]
      @http_lib = http_lib
    end

    # Makes the HTTP Call, returns a MailTools::Result object
    def sendmail
      begin
        uri     = URI(@url)
        request = (@qmsg.options[:json_extra] || {}).merge(
                  {return_path:@qmsg.return_path,
                   recipients: @qmsg.recipients,
                   message:    @qmsg.message})
        res     = @http_lib.post_form(uri, request)
        ok      = res.code.to_i < 300 ? MailTools::EXIT_OK : MailTools::ERRORS[1]
        MailTools::Result.new(@qmsg, :http, ok, res.message, res.body)
      rescue SocketError => e
        res = e
        MailTools::Result.new(@qmsg, :http, MailTools::EXIT_ERROR, e.message)
      end
    end

    def receive
    end
  end
end
