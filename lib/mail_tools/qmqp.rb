module MailTools

  # Transfers a message to another mail server using MailTools's QMQP protocol.
  #   http://cr.yp.to/proto/qmqp.html
  #
  # This is not intended as a delivery transport. It transfers the message
  # as a queue object (message, return path, recipients) to another server
  # for delivery. The remote server runs a "mail_tools-qmqpd" daemon to accept
  # the message. Postfix also ships with a QMQP listener so can be used as
  # the target MTA.
  #
  # Usage:
  #
  #   MailTools::QMQP.sendmail(mail_tools_message) #=> MailTools::Result
  #
  class QMQP

    def self.sendmail(mail_tools_message)
      MailTools::QMQP.new(mail_tools_message).sendmail
    end

    def initialize(mail_tools_message)
      @qmsg = mail_tools_message
    end

    def sendmail(mail_tools_message=nil)
      @qmsg    = mail_tools_message if mail_tools_message
      begin
        ip     = @qmsg.options[:ip]   || qmqp_server
        port   = @qmsg.options[:port] || MailTools::Config.qmqp_port
        #p "opening socket to...", ip, port
        socket = TCPSocket.new(ip, port)
        #p "socket!", socket
        if socket
          socket.send(@qmsg.to_netstring, 0)
          #p "waiting fore response"
          @response = socket.recv(1000)
        end
        socket.close
        MailTools::Result.new(@qmsg, :qmqp, MailTools::EXIT_OK, @response, "#{ip}:#{port}")

      rescue SocketError, SystemCallError => e
        socket.close if socket
        MailTools::Result.new(@qmsg, :qmqp, MailTools::ERRORS[1], e.to_s, "#{ip}:#{port}")
      end
    end

    def qmqp_server(i=0)
      dir = @qmsg.options[:mail_tools_dir] || MailTools::Config.mail_tools_dir
      filename = "#{dir}/control/qmqpservers"
      return '127.0.0.1' unless File.exists?(filename)
      File.readlines(filename)[i].chomp
    end

  end

end
