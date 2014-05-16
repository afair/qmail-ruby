module Qmail

  # Delivers a Message to a Mailbox File in mbox format:
  #
  #   From MAILER-DAEMON Fri Jul  8 12:08:34 2011
  #   From: Author <author@example.com>
  #   To: Recipient <recipient@example.com>
  #   Subject: Sample message 1
  #
  #   This is the body.
  #   >From (should be escaped).
  #   There are 3 lines.
  #
  class Mailbox
    include Enumerable

    def self.sendmail(qmail_message, filepath)
      Qmail::Mailbox.new(filepath).sendmail(qmail_message)
    end

    def initialize(filepath)
      @filepath = filepath
    end

    def sendmail(qmail_message)
      write_message(qmail_message)
    end

    def write_message(msg)
      File.open(@filepath,'a') do |f|
        f.flock(File::LOCK_EX)
        f.puts "From #{msg.return_path} #{Time.new.strftime("%a %b %e %H:%M:%S %Y")}"
        f.puts msg.message.gsub(/^(\>*From )/, '\>$1'), "\n"
      end
    end

    def each
      File.open(@filepath,'r') do |f|
        f.flock(File::LOCK_EX)
        separator = f.gets.chomp.match(/\AFrom (\S+) (.+)/)
        return nil unless separator
        msg = ''
        while !f.eof
          line = f.gets.chomp
          if m = line.match(/\AFrom (\S+) (.+)/)
            yield Qmail::Message.new(msg.gsub(/^\>(\>*From)/,'$1'), separator[1]), separator[2]
            msg = ''
            separator = m
          else
            msg += line + "\n"
          end
        end
        yield Qmail::Message.new(msg, separator[1]) if msg > ' '
      end
    end

    # Like Enumerable select, but saves messages returning true from block,
    # returns count of kept messages
    def keep
      f = Tempfile.new
      msgs = 0
      each do |msg, delivered_at|
        if yield(msg, delivered_at)
          msgs += 1
          f.puts "From #{msg.return_path} #{Time.new.strftime("%a %b %e %H:%M:%S %Y")}"
          f.puts msg.message.gsub(/^(\>*From )/, '\>$1'), "\n"
        end
      end
      f.close
      File.rename(f.path, @filepath) if msgs
      msgs
    end

    # Returns the number of messages in the Mailbox
    def size
      inject(0)  {|m,i| m+=1}
    end
    alias :count :size

  end
End
