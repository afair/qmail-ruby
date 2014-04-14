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
  #   Qmail::QMQP.sendmail(qmail_message) #=> Qmail::Result
  #
  class QMQP

    def self.sendmail(qmail_message)
      Qmail::SMTP.new(qmail_message).sendmail
    end

    def initialize(qmail_message)
      @qmsg = qmail_message
    end

    def sendmail(qmail_msg=nil)
      @qmsg    = qmail_message if qmail_message
      begin
        ip     = @qmsg.options[:ip] || qmqp_server
        port   = @qmsg.options[:port] || 628
        socket = TCPSocket.new(ip, @options[:port])
        if socket
          socket.send(@qmsg.to_netstring, 0)
          @response = socket.recv(1000)
        end

      rescue SocketError => e
        @response = e
      ensure
        socket.close if socket
        Qmail::Result.new(@qmsg, :qmqp, @success, @response, "#{ip}:#{port}")
      end
    end

    def qmqp_server(i=0)
      dir = @qmsg.option[:qmail_dir] || '/var/qmail'
      filename = "#{dir}/control/qmqpservers"
      return '127.0.0.1' unless File.exists?(filename)
      File.readlines(filename)[i].chomp
    end

  end

end
