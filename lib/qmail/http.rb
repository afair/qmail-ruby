require 'net/http'

module Qmail
  class HTTP

    def self.sendmail(qmail_message)
      Qmail::SMTP.new(qmail_message).sendmail
    end

    def initialize(qmail_message)
      @qmsg = qmail_message
    end

    # Builds the QMQP request, and opens a connection to the QMQP Server and sends
    # This implemtents the QMQP protocol, so does not need Qmail installed on the host system.
    # System defaults will be used if no ip or port given.
    # Returns true on success, false on failure (see @response), or nul on deferral
    def sendmail(url=nil, qmail_message=nil)
      @qmsg   = qmail_message if qmail_message
      url   ||= @qmsg.options[:http_url]

      begin
        uri = URI(url)
        res = Net::HTTP.poste_form(uri, 'return_path'=>@qmsg.return_path,
                                   'recipients'=>@qmsg.recipients,
                                   'message'=>@qmsg.message)

        res.code < '300' ? true : false

      rescue SocketError => e # getaddrinfo: nodename nor servname provided, or not known
        Qmail.log(:error, "HTTP Failure: #{res.inspect}" )
        raise e

      ensure
        socket.close if socket
      end
    end
  end
end
