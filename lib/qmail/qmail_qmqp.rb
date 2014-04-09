module Qmail
  
  # Spawms a Qmail-queue process to insert the message
  class Qmqp
    # Builds the QMQP request, and opens a connection to the QMQP Server and sends
    # This implemtents the QMQP protocol, so does not need Qmail installed on the host system.
    # System defaults will be used if no ip or port given.
    # Returns true on success, false on failure (see @response), or nul on deferral
    def self.qmqp(return_path=nil, recipients=nil, message=nil, *options)
      parameters(return_path, recipients, message, options)
      
      begin
        ip = @options[:ip] || File.readlines(QMQP_SERVERS).first.chomp
        #puts "CONNECT #{:ip}, #{@options[:qmqp_port]}"
        socket = TCPSocket.new(ip, @options[:qmqp_port])
        raise "QMQP can not connect to #{ip}:#{@options[:qmqp_port]}" unless socket
        
        # Build netstring of messagebody+returnpath+recipient...
        nstr = Qmail::Netstring.of(@message.map.join("\n")+"\n")
        nstr += Qmail::Netstring.of(@return_path)
        nstr += @recipients.map { |r| Qmail::Netstring.of(r) }.join
        socket.send( Qmail::Netstring.of(nstr), 0 )

        @response = socket.recv(1000) # "23:Kok 1182362995 qp 21894," (it's a netstring)
        @success = case @response.match(/^\d+:([KZD])(.+),$/)[1]
          when 'K' then true  # success
          when 'Z' then nil   # deferral
          when 'D' then false # failure
          else false
        end
        logmsg = "RubyQmail QMQP [#{ip}:#{@options[:qmqp_port]}]: #{@response} return:#{@success}"
        @options[:logger].info(logmsg)
        puts logmsg
        @success
      rescue Exception => e
        @options[:logger].error( "QMQP can not connect to #{@opt[:qmqp_ip]}:#{@options[:qmqp_port]} #{e}" )
        raise e
      ensure
        socket.close if socket
      end
    end
  end

end
