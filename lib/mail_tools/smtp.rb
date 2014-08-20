require 'net/smtp'
require 'thread'
require 'timeout'

module MailTools

  # Sends Email via SMTP
  # Usage:
  #   MailTools::Qmail::SMTP.mail(mailtools_message)
  #
  class SMTP

    def self.mail(msg)
      MailTools::SMTP.new(msg).mail
    end

    def initialize(msg)
      @msg = msg
    end

    def mail(threads=10)
      queue = Queue.new
      @msg.recipients.each { |r| queue << r }
      semaphore = Mutex.new
      results = []

      workers = (0..threads).map do
        Thread.new do
          begin
            while r = queue.pop(true)
              result = smtp_recipient(r)
              semaphore.synchronize { results << result }
            end
          rescue ThreadError
          end
        end
      end
      workers.map(&:join); 
      results
    end

    def smtp_recipient(recip)
      begin
        _, recip_host = recip.split(/@/,2)
        helo_host = MailTools::Config.smtp_helo_host || `hostname`.chomp
        smtp_class= MailTools::Config.smtp_class || Net::SMTP
        resp = smtp_class.start(recip_host, 25, helo_host) do |smtp|
          smtp.send_message(@msg.message, @msg.return_path, recip)
        end
        resp
      rescue SocketError, SystemCallError => e
        socket.close if socket
        MailTools::Result.new(@msg, :qmqp, MailTools::ERRORS[1], e.to_s, "#{ip}:#{port}")
      end
    end

    # Returns the configured QMQP server ip address
    def qmqp_server(i=0)
      dir = @msg.options[:mail_tools_dir] || MailTools::Config.mail_tools_dir
      filename = "#{dir}/control/qmqpservers"
      return '127.0.0.1' unless File.exists?(filename)
      File.readlines(filename)[i].chomp
    end

    # Takes a socket with an incoming qmqp message, returns the message
    def self.receive_mail(io)
      Message.new(message, return_path, recipients)
    end

    def smtp_protocol(io)
      return_path = ''
      message = recipients = []

      Timeout::timeout(10) do
        loop do
          line = io.readpartial(4096)
          case line
          when /^(HELO|EHLO)/
            io.print "250 #{Socket.gethostname} go on...\r\n"
          when /^QUIT/
            io.close
            return nil
          when (/^MAIL FROM\:\s*<?(.+)>?/)
            return_path = $1
            io.print "250 OK\r\n"
          when (/^RCPT TO\:/)
            Thread.current[:message][:to] << line.gsub(/^RCPT TO\:/, '').strip
            io.print "250 OK\r\n"
          when (/^DATA/)
            Thread.current[:data_mode] = true
            io.print "354 Enter message, ending with \".\" on a line by itself\r\n"
            while data = io.readpartial(4096) && data.chomp != '.'
              message << data.chomp
            end
            io.print "250 OK\r\n"
            io.close
            break
          else
            io.print "502 NOT IMPLEMENTED\r\n"
          end
        end
      end
      #io.print "221 bye\r\n" #????
      #io.close
      Message.new(message.join("\n"), return_path, recipients)
    end

    # Simple server, for prototyping
    def self.server(port=MailTools::Config.smtp_port, max_accepts=-1, &block)
      begin
        server = TCPServer.new(MailTools::Config.smtp_ip||"127.0.0.1", port||25)
        while max_accepts != 0
          Thread.start(server.accept) do |client|
            msg = receive_mail(client)
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
