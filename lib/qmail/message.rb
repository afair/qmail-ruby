require 'digest/md5'
require 'json'

module Qmail
  # Constructs a Qmail Queue Message Oject. It is used as a standard interface
  # for classes in this library. A queue message has its payload data (also
  # named message within) which is a complete RFC822-style email message, with
  # full headers, bodies and attachments.
  #
  # It also includes the SMTP envelope consisting of the return path and list
  # of recipient email addresses. The return path is an email, usually the sender's
  # address, to which undeliverable or "bounced" messages will be returned.
  #
  # This library can to use VERP (Variable Envelope Return Path) extentions
  # on the return path, so automated bounce detection becomes easier. With VERP,
  # the recipient's email address is piggybacked onto the mailbox of the sender,
  # replacing the @ by an = in the resulting address.
  #
  #      sender+recipient=example.com@example.com
  #
  # Provide a facility that can accept these email addresses, usually as an address
  # tag. Append your separator character (ususally + - or =) to the local part.
  #
  #     sender+@gmail.com
  #
  # This will create the VERP return path illustrated above.
  #
  class Message
    attr_accessor :message, :return_path, :recipients, :options

    # Message.new("message", "return_path@example.com", "recip1@example.com", ...., {option:value})
    def initialize(*args)
      self.options     = args.last.is_a?(Hash) ? args.pop : {}
      self.message     = args.shift || ''
      self.return_path = args.shift || ''
      self.recipients  = args
      load_mailfile(options[:mailfile])             if options[:mailfile]
      self.recipient_file(options[:recipient_file]) if options[:recipient_file]
      use_headers                                   if options[:headers]
    end

    # Sets the return path, and optionally alters it to the VERP format if enabled
    # That format is "returnpath-@domain-@[]" The hyphen before the @ will be inserted
    # unless another punctuation character (not alpha-numeric) is already there.
    # The "-@[]" suffix is a signal for qmail to use VERP, and alter the return path
    # by inserting the recipient's mailbox, '=' and domain before the '@'
    # giving `me-you=example.com@example.com`
    def return_path=(email_address)
      if (!!options.fetch(:verp) { Qmail::Config.verp })
        email_address  = email_address.sub(/@/, '-@') if email_address =~ /\w@/
        email_address += '-@[]'
      end
      @return_path     = email_address
    end

    def load_mailfile(filename)
      m                = Qmail::Maildrop.mailfile(filename)
      self.message     = m.message
      self.return_path = m.return_path
      self.recipients  = m.recipients
      self.options     = m.options
    end

    def use_headers
      h = message_headers
      self.return_path = addresses(h[:from]).first
      recips =  []
      [:to, :cc, :bcc].each do |hdr|
        recips << addresses(h[hdr])
      end
      self.recipients = recips.flatten
      remove_bcc_header
    end

    def message_headers
      head, _   = self.message.split(/\n\s*\n/,2)
      headlines = head.split(/\n(?=\w)/s)
      headers   = {}
      headlines.each do |h|
        n,v = h.chomp.split(/:\s*/, 2)
        headers[n.downcase.to_sym] = v.gsub(/\n\s*/, ' ')
      end
      headers
    end

    def remove_bcc_header
      head, body   = self.message.split(/\n\s*\n/,2)
      headlines = head.split(/\n(?=\w)/s)
      head = headlines.reject { |h| h =~ /\ABcc:/i }.join("\n")
      self.message = head + "\n" + body
    end

    # Calls the sendmail method on the proper protocol class. Returns a
    # Qmail::Result Object with the response.
    def sendmail(method=nil)
      method ||= self.options[:method] || :queue
      send(method) if %i(queue qmqp smtp maildrop http).include?(method)
    end

    def queue
      Qmail::Inject.sendmail(self)
    end

    def qmqp
      Qmail::QMQP.sendmail(self)
    end

    def smtp
      Qmail::SMTP.sendmail(self)
    end

    def maildrop(dir=nil)
      Qmail::Maildrop.sendmail(self, dir || self.options[:maildrop_dir])
    end

    def http(url=nil)
      Qmail::HTTP.sendmail(self, url || self.options[:http_url])
    end

    def recipient_file(filename)
      File.readlines(filename).each do |rec|
        self.recipients.push($1) if rec =~ /\A\s*(\S+@\S)/
      end
    end

    # Build netstring of messagebody+returnpath+recipient...
    def to_netstring
      nstr = Qmail::Netstring.of(self.message+"\n")
      nstr += Qmail::Netstring.of(self.return_path)
      self.recipients.each { |r| nstr += Qmail::Netstring.of(r) }
      Qmail::Netstring.of(nstr)
    end

    def to_md5
      Digest::MD5.hexdigest(self.message + self.return_path +
                            self.recipients.join(' '))
    end

    def to_json
      {message:self.message, return_path:self.return_path,
       recipients:self.recipients}.to_json
    end

    def to_s
      [self.return_path, *self.recipients, "", self.message].join("\n")
    end

    private

    def addresses(str)
      a = []
      return a unless str
      #str.split(/([\w\.\=\-\+]+\@[\w\-\.]+\w)/).each {|e| a << e if e =~/@/ }
      while m = str.match(/\A.*?([\w\.\=\-\+]+\@[\w\-\.]+\w)(.*)/)
        a << m[1]
        str = m[2]
      end
      a
    end
  end

end
