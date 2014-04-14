module Qmail

  # The Qmail::Inject class inserts a message into the queue
  # The name comes from the qmail-inject command. It spawns
  # off qmail-queue and writes the message and envelope into
  # its designated file handles.
  #
  # Qmail-queue Protocol:
  # 1. Reads mail message from File Descriptor 0 until closed
  # 2. reads Envelope from FD 1. Envelope Stream:
  #    * "F" + sender_email + "\0"
  #    * "T" + recipient_email + "\0" (for each recipient)
  #    * Final "\0" to signal end of recipients.
  #
  class Inject
    include Process

    # Single-step processor. Takes an instance of Qmail::Message
    # Returns a Qmail::Result object
    def self.sendmail(qmail_message)
      inject = Qmail::Inject.new(qmail_message)
      inject.sendmail
    end

    def initialize(qmail_message)
      @qmsg = qmail_message
    end

    # This calls the Qmail-Queue program, so requires qmail to be installed (does not require it to be currently running).
    # Returns a Qmail::Result object
    def sendmail
      run_qmail_queue(Qmail::Config.qmail_queue) do |msg, env|
        # Send the Message
        msg.puts @qmsg.message
        msg.close

        env.write('F' + @qmsg.return_path + "\0")
        @qmsg.recipients.each { |r| env.write('T' + r + "\0") }
        env.write("\0") # End of "file"
      end

      Qmail::Result.new(@qmsg, :queue, @exit_code)
    end

    private

    # Forks, sets up stdin and stdout pipes, and starts qmail-queue.
    # If a block is passed, yields to it with [sendpipe, receivepipe],
    # and returns the exist cod, otherwise returns {:msg=>pipe, :env=>pipe, :pid=>@child}
    # It exits 0 on success or another code on failure.
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
        env_write.close
        wait(@child)
        @exit_code = $? >> 8
        return @exit_code
      end
    end

  end

end
