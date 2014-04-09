module Qmail
  
  # Spawms a Qmail-queue process to insert the message
  class QmailQueue
    include Process
    QMAIL_QUEUE_SUCCESS = 0
    QMAIL_ERRORS = {
      -1 => "Unknown Error",
       0 => "Success",
      11 => "Address too long",
      31 => "Mail server permanently refuses to send the message to any recipients.",
      51 => "Out of memory.",
      52 => "Timeout.",
      53 => "Write error; e.g., disk full.",
      54 => "Unable to read the message or envelope.",
      55 => "Unable to read a configuration file.",
      56 => "Problem making a network connection from this host.",
      61 => "Problem with the qmail home directory.",
      62 => "Problem with the queue directory.",
      63 => "Problem with queue/pid.",
      64 => "Problem with queue/mess.",
      65 => "Problem with queue/intd.",
      66 => "Problem with queue/todo.",
      71 => "Mail server temporarily refuses to send the message to any recipients.",
      72 => "Connection to mail server timed out.",
      73 => "Connection to mail server rejected. ",
      74 => "Connection to mail server  succeeded,  but  communication  failed.",
      81 => "Internal bug; e.g., segmentation fault.",
      91 => "Envelope format error"
    }
    
    # This calls the Qmail-Queue program, so requires qmail to be installed (does not require it to be currently running).
    def queue(return_path=nil, recipients=nil, message=nil, *options)
      parameters(return_path, recipients, message, options)
      @success = run_qmail_queue() do |msg, env|
        # Send the Message
        @message.each { |m| msg.puts(m) }
        msg.close

        env.write('F' + @return_path + "\0")
        @recipients.each { |r| env.write('T' + r + "\0") }      
        env.write("\0") # End of "file"
      end
      @options[:logger].info("RubyQmail Queue exited:#{@success} #{Queue.qmail_queue_error_message(@success)}")
      return true if @success == QMAIL_QUEUE_SUCCESS
      raise Queue.qmail_queue_error_message(@success)
    end
    
    # Maps the qmail-queue exit code to the error message
    def self.qmail_queue_error_message(code) #:nodoc:
      "RubyQmail::Queue Error #{code}:" + QMAIL_ERRORS.has_key?(code) ? QMAIL_ERRORS[code]:QMAIL_ERRORS[-1]
    end
    

    # Forks, sets up stdin and stdout pipes, and starts qmail-queue. 
    # If a block is passed, yields to it with [sendpipe, receivepipe], 
    # and returns the exist cod, otherwise returns {:msg=>pipe, :env=>pipe, :pid=>@child}
    # It exits 0 on success or another code on failure. 
    # Qmail-queue Protocol: Reads mail message from File Descriptor 0, then reads Envelope from FD 1
    # Envelope Stream: 'F' + sender_email + "\0" + ("T" + recipient_email + "\0") ... + "\0"
    def run_qmail_queue(command=nil, &block)
      # Set up pipes and qmail-queue child process
      msg_read, msg_write = IO.pipe
      env_read, env_write = IO.pipe
      @child=fork # child? nil : childs_process_id

      unless @child 
        ## Set child's stdin(0) to read from msg
        $stdin.close # FD=0
        msg_read.dup
        msg_read.close
        msg_write.close

        ## Set child's stdout(1) to read from env
        $stdout.close # FD=1
        env_read.dup
        env_read.close
        env_write.close

        # Change directory and load command
        Dir.chdir(@options[:qmail_root])
        exec( command || @options[:qmail_queue] )
        raise "Exec qmail-queue failed"
      end

      # Parent Process with block
      if block_given?
        yield(msg_write, env_write)
      # msg_write.close
        env_write.close
        wait(@child)
        @success = $? >> 8
        # puts "#{$$} parent waited for #{@child} s=#{@success} #{$?.inspect}"
        return @sucess
      end
      
      # Parent process, no block
      {:msg=>msg_write, :env=>env_write, :pid=>@child}
    end

  end

end
