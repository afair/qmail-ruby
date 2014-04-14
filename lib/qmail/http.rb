require 'net/http'

module Qmail
  class HTTP

    def self.sendmail(qmail_message, url)
      Qmail::HTTP.new(qmail_message, url).sendmail
    end

    def initialize(qmail_message, url=nil, http_lib=Net::HTTP)
      @qmsg     = qmail_message
      @url      = url || @qmsg.options[:http_url]
      @http_lib = http_lib
    end

    # Makes the HTTP Call, returns a Qmail::Result object
    def sendmail
      begin
        uri     = URI(@url)
        request = (@qmsg.options[:json_extra] || {}).merge(
                  {return_path:@qmsg.return_path,
                   recipients: @qmsg.recipients,
                   message:    @qmsg.message})
        res     = @http_lib.post_form(uri, request)
        ok      = res.code.to_i < 300 ? Qmail::EXIT_OK : Qmail::ERRORS[1]
        Qmail::Result.new(@qmsg, :http, ok, res.message, res.body)
      rescue SocketError => e
        res = e
        Qmail::Result.new(@qmsg, :http, Qmail::EXIT_ERROR, e.message)
      end
    end
  end
end
