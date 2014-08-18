module MailTools

  # The MailTools::Inject class inserts a message into the queue
  # The name comes from the mail_tools-inject command. It spawns
  # off mail_tools-queue and writes the message and envelope into
  # its designated file handles.
  #
  # MailTools-queue Protocol:
  # 1. Reads mail message from File Descriptor 0 until closed
  # 2. reads Envelope from FD 1. Envelope Stream:
  #    * "F" + sender_email + "\0"
  #    * "T" + recipient_email + "\0" (for each recipient)
  #    * Final "\0" to signal end of recipients.
  #
  class Inject
    include Process

    # Single-step processor. Takes an instance of MailTools::Message
    # Returns a MailTools::Result object
    def self.sendmail(mail_tools_message, mail_tools_queue_command=nil)
      inject = MailTools::Inject.new(mail_tools_message, mail_tools_queue_command)
      inject.sendmail
    end

    def initialize(mail_tools_message, mail_tools_queue_command=nil)
      @qmsg = mail_tools_message
      @command = mail_tools_queue_command || MailTools::Config.mail_tools_queue
    end

    # This calls the MailTools-Queue program, so requires mail_tools to be installed (does not require it to be currently running).
    # Returns a MailTools::Result object
    def sendmail
      run_mail_tools_queue(@command) do |msg, env|
        # Send the Message
        msg.puts @qmsg.message
        msg.close

        env.write('F' + @qmsg.return_path + "\0")
        p @qmsg.recipients
        @qmsg.recipients.each { |r| env.write('T' + r + "\0") }
        env.write("\0") # End of "file"
      end

      MailTools::Result.new(@qmsg, :queue, @exit_code)
    end

    private

    # Forks, sets up stdin and stdout pipes, and starts mail_tools-queue.
    # If a block is passed, yields to it with [sendpipe, receivepipe],
    # and returns the exist cod, otherwise returns {:msg=>pipe, :env=>pipe, :pid=>@child}
    # It exits 0 on success or another code on failure.
    def run_mail_tools_queue(command, &block)
      # Set up pipes and mail_tools-queue child process
      msg_read, msg_write = IO.pipe
      env_read, env_write = IO.pipe
      @child=fork # child? ? nil : childs_process_id
      mail_tools_dir = @qmsg.options[:mail_tools_root] || MailTools::Config.mail_tools_dir
      raise "MailTools Dir not found: #{mail_tools_dir}" unless Dir.exist?(mail_tools_dir)

      unless @child # I'm the child
        ## Set child's stdin(0) to read from msg
        $stdin.close # FD=0
        msg_read.dup
        msg_read.close
        msg_write.close

        ## Set child's stdout(1) to read from envelope
        $stdout.close # FD=1
        env_read.dup
        env_read.close
        env_write.close

        # Change directory and load command
        Dir.chdir(mail_tools_dir)
        exec(*command.split)
        raise "Exec #{command} failed"
      end

      # Parent Process with block
      if block_given?
        msg_write.sync = true
        env_write.sync = true
        block.call(msg_write, env_write)
        env_write.close
        sleep 1
        Process.wait(@child)
        #p "?=#{$?}; >>=#{$?>>8}"
        @exit_code = $? >> 8
        return @exit_code
      else
        return [msg_write, env_write, @child]
      end
    end

  end

end
