module Qmail

  # Sends Email via SMTP using the qmail-remote command
  class QmailRemote

    # Sends email directly via qmail-remote. It does not store in the queue, It will halt the process
    # and wait for the network event to complete. If multiple recipients are passed, it will run
    # qmail-remote delivery for each at a time to honor VERP return paths.
    def run(return_path=nil, recipients=nil, message=nil, *options)
      parameters(return_path, recipients, message, options)
      rp1, rp2 = @return_path.split(/@/,2)
      rp = @return_path
      @recipients.each do |recip|
        unless @options[:noverp]
          mailbox, host = recip.split(/@/)
          rp = "#{rp1}#{mailbox}=#{host}@#{rp2}"
        end

        @message.rewind if @message.respond_to?(:rewind)
        cmd = "#{@options[:qmail_root]}+/bin/qmail-remote #{host} #{rp} #{recip}"
        @success = self.spawn_command(cmd) do |send, recv|
          @message.each { |m| send.puts m }
          send.close
          @response = recv.readpartial(1000)
        end

        @options[:logger].info("RubyQmail Remote #{recip} exited:#{@success} responded:#{@response}")
      end
      return [ @success, @response ] # Last one
    end

    # Forks, sets up stdin and stdout pipes, and starts the command. 
    # IF a block is passed, yeilds to it with [sendpipe, receivepipe], 
    # returing the exit code, otherwise returns {:send=>, :recieve=>, :pid=>}
    # qmail-queue does not work with this as it reads from both pipes.
    def spawn_command(command, &block)
      child_read, parent_write = IO.pipe # From parent to child(stdin)
      parent_read, child_write = IO.pipe # From child(stdout) to parent
      @child = fork

      # Child process
      unless @child # 
        $stdin.close # closes FD==0
        child_read.dup # copies to FD==0
        child_read.close

        $stdout.close # closes FD==1
        child_write.dup # copies to FD==1
        child_write.close

        Dir.chdir(@options[:qmail_root]) unless @options[:nochdir]
        exec(command)
        raise "Exec spawn_command #{command} failed"
      end

      # Parent Process with block
      if block_given?
        yield(parent_write, parent_read)
        parent_write.close
        parent_read.close
        wait(@child)
        @success = $? >> 8
        return @sucess
      end

      # Parent process, no block
      {:send=>parent_write, :receive=>parent_read, :pid=>@child}
    end

  end

end
