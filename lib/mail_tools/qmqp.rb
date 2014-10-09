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
  #   MailTools::QMQP.deliver(mail_tools_message) #=> MailTools::Result
  #
  class QMQP

    def self.deliver(msg, options={})
      MailTools::QMQP.new(options).deliver(msg)
    end

    def initialize(options={})
      @options = MailTools::Config.qmail.merge(options)
    end

    def deliver(mail_tools_message=nil)
      msg    = mail_tools_message if mail_tools_message
      begin
        ip     = @options[:ip]   || qmqp_server
        port   = @options[:port] || MailTools::Config.qmqp_port
        socket = TCPSocket.new(ip, port)
        if socket
          socket.send(msg.to_netstring, 0)
          socket.close_write
          @response = socket.recv(1000)
        end
        socket.close
        MailTools::Result.new(msg, :qmqp, MailTools::EXIT_OK, @response, "#{ip}:#{port}")

      rescue SocketError, SystemCallError => e
        socket.close if socket
        MailTools::Result.new(msg, :qmqp, MailTools::ERRORS[1], e.to_s, "#{ip}:#{port}")
      end
    end

    # Returns the configured QMQP server ip address
    def qmqp_server(i=0)
      return @options[:qmqp_server] if @options[:qmqp_server]
      dir = @options[:dir] || '/var/qmail'
      filename = "#{dir}/control/qmqpservers"
      return '127.0.0.1' unless File.exists?(filename)
      File.readlines(filename)[i].chomp
    end

    # Takes a socket with an incoming qmqp message, returns the message
    def self.receive(io)
      b = ''
      while (ch = io.read(1)) =~ /\d/
        b += ch
      end
      msg = io.read(b.to_i)
      message = Message.from_netstring("#{b}:" + msg + ',')

      if message
        io.puts MailTools::Netstring.encode("Kok #{Time.now.to_i} qp #{$$}")
      else
        io.puts MailTools::Netstring.encode("DError in message")
      end

      message
    end

    # Simple server, for prototyping
    def self.server(port=MailTools::Config.qmqp_port, max_accepts=-1, &block)
      begin
        server = TCPServer.new(MailTools::Config.qmqp_ip||"127.0.0.1", port)
        while max_accepts != 0
          Thread.start(server.accept) do |client|
            msg = receive(client)
            client.close
            block.call(msg) if msg
            max_accepts -= 1
          end
        end
      rescue Exception => e
        puts "Exception! #{e}"
      end
    end
  end

end
