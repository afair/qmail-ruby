module Qmail
  
  # Transfers a message to another mail server using Qmail's QMQP protocol.
  #   http://cr.yp.to/proto/qmqp.html
  #
  # This is not intended as a delivery transport. It transfers the message
  # as a queue object (message, return path, recipients) to another server
  # for delivery. The remote server runs a "qmail-qmqpd" daemon to accept
  # the message. Postfix also ships with a QMQP listener so can be used as
  # the target MTA.
  #
  # Usage:
  #
  #   Qmail::QMQP.sendmail(qmail_message)
  #
  class QMQP

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
    def sendmail(qmail_msg=nil)
      @qmsg = qmail_message if qmail_message
      begin
        ip   = @qmsg.options[:ip] || qmqp_server
        port = @qmsg.options[:port] || 628
        socket = TCPSocket.new(ip, @options[:port])
        raise "QMQP can not connect to #{ip}:#{port}" unless socket
        
        socket.send(@qmsg.to_netstring, 0)
        parse_qmail_response(socket.recv(1000))
        logmsg = "RubyQmail QMQP [#{ip}:#{@options[:port]}]: #{@response} return:#{@success}"
        @qmsg.options[:logger].info(logmsg) if @qmsg.options[:logger]
        {sucess:@sucess, qmail_id:@email_msgid, response:@response}

      rescue Exception => e
        @options[:logger].error( "QMQP can not connect to #{@opt[:qmqp_ip]}:#{@options[:qmqp_port]} #{e}" )
        raise e

      ensure
        socket.close if socket
      end
    end

    def qmqp_server(i=0)
      dir = @qmsg.option[:qmail_dir] || '/var/qmail'
      filename = "#{dir}/control/qmqpservers"
      return '127.0.0.1' unless File.exists?(filename)
      File.readlines(filename)[i].chomp
    end

    # "23:Kok 1182362995 qp 21894," (it's a netstring)
    def parse_qmail_response(response)
      m =  response.match(/\A\d+:([KZD]) (.+) qp (.+)/)
      success = false
      case m[1]
      when 'K'
        sucess = true
      when 'Z' # Deferral, try again later
        sucess = nil
      when 'D'
        sucess = false
      else false
      end

      @response = response
      @qmail_msgid = m[3]
      @success = success
    end
  end

end
