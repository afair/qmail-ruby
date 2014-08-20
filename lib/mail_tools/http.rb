require 'net/http'

module MailTools
  class HTTP

    def self.deliver(mail_tools_message, url, options={})
      MailTools::HTTP.new(url, options).deliver(mail_tools_message)
    end

    def initialize(url, options={})
      @url      = url
      @options  = options
      @http_lib = options[:http_lib] || Net::HTTP
    end

    # Makes the HTTP Call, returns a MailTools::Result object
    def deliver(msg)
      begin
        request = (@options[:params] || {}).merge(
                  {return_path:msg.return_path,
                   recipients: msg.recipients,
                   message:    msg.message})

        res     = @http_lib.post_form(URI(@url), request)
        ok      = res.code.to_i < 300 ? MailTools::EXIT_OK : MailTools::EXIT_ERROR.first
        MailTools::Result.new(msg, :http, ok, res.message, res.body)
      rescue SocketError => e
        res = e
        MailTools::Result.new(msg, :http, MailTools::EXIT_ERROR, e.message)
      end
    end

    def receive(params)
      Message.new(params[:message], params[:return_path], params[:recipients])
    end
  end
end
