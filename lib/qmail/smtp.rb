require 'net/smtp'

module Qmail

  # Sends Email via SMTP using the qmail-remote command
  # Usage:
  #   Qmail::SMTP.sendmail(qmail_message)
  #
  #   - qmail_message is Qmail::Message.new(message, return_path, recipients, options)
  #
  class SMTP

    def self.sendmail(qmail_message)
      Qmail::SMTP.new(qmail_message).sendmail
    end

    def initialize(qmail_message)
      @qmsg = qmail_message
    end

    # Sends email directly via qmail-remote. It does not store in the queue, It will halt the process
    # and wait for the network event to complete. If multiple recipients are passed, it will run
    # qmail-remote delivery for each at a time to honor VERP return paths.
    def sendmail
      cmdfile = "#{@qmsg.options[:qmail_root]}/bin/qmail-remote"
      return smtp unless File.exists?(cmdfile)

      rp1, rp2 = @qmsg.return_path.split(/@/,2)
      rp = @qmsg.return_path
      @qmsg.recipients.each do |recip|
        unless @qmsg.options[:noverp]
          mailbox, host = recip.split(/@/)
          rp = "#{rp1}#{mailbox}=#{host}@#{rp2}"
        end

        cmd = "#{cmdfile} #{host} #{rp} #{recip}"
        @success = self.spawn_command(cmd) do |send, recv|
          send.puts @qmsg.message
          send.close
          @response = recv.readpartial(1000)
        end

        #@options[:logger].info("RubyQmail Remote #{recip} exited:#{@success} responded:#{@response}")
      end
      return [ @success, @response ] # Last one
    end

    # Forks, sets up stdin and stdout pipes, and starts the command. 
    # IF a block is passed, yields to it with [sendpipe, receivepipe], 
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

    def smtp
      @qmsg.recipients.each do |r|
        _, recip_host = r.split(/@/,2)
        Net::SMTP.start(recip_host, 25) do |smtp|
          smtp.send_message(@qmsg.message, @qmsg.return_path, r)
        end
      end
    end

  end
end
