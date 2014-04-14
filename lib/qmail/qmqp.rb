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
      Qmail::QMQP.new(qmail_message).sendmail
    end

    def initialize(qmail_message)
      @qmsg = qmail_message
    end

    def sendmail(qmail_message=nil)
      @qmsg    = qmail_message if qmail_message
      begin
        ip     = @qmsg.options[:ip]   || qmqp_server
        port   = @qmsg.options[:port] || Qmail::Config.qmqp_port
        #p "opening socket to...", ip, port
        socket = TCPSocket.new(ip, port)
        #p "socket!", socket
        if socket
          socket.send(@qmsg.to_netstring, 0)
          #p "waiting fore response"
          @response = socket.recv(1000)
          p @response
        end
        socket.close
        Qmail::Result.new(@qmsg, :qmqp, Qmail::EXIT_OK, @response, "#{ip}:#{port}")

      rescue SocketError, SystemCallError => e
        socket.close if socket
        Qmail::Result.new(@qmsg, :qmqp, Qmail::ERRORS[1], e.to_s, "#{ip}:#{port}")
      end
    end

    def qmqp_server(i=0)
      dir = @qmsg.options[:qmail_dir] || Qmail::Config.qmail_dir
      filename = "#{dir}/control/qmqpservers"
      return '127.0.0.1' unless File.exists?(filename)
      File.readlines(filename)[i].chomp
    end

  end

end
