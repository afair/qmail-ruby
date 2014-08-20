require 'digest/md5'
require 'json'

module MailTools
  # Constructs a MailTools Queue Message Oject. It is used as a standard interface
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
      self.recipients  = args.flatten
      read_message(options[:mailhandle])            if options[:mailhandle]
      load_mailfile(options[:mailfile])             if options[:mailfile]
      self.recipient_file(options[:recipient_file]) if options[:recipient_file]
      use_headers                                   if options[:headers]
    end

    # Reads a message from a file, uses From/To headers for return path and recipients.
    def self.read(filename, options={})
      msg = Message.new(File.read(filename), options)
      msg.use_headers
      msg
    end

    # Sets the return path, and optionally alters it to the VERP format if enabled
    # That format is "returnpath-@domain-@[]" The hyphen before the @ will be inserted
    # unless another punctuation character (not alpha-numeric) is already there.
    # The "-@[]" suffix is a signal for mail_tools to use VERP, and alter the return path
    # by inserting the recipient's mailbox, '=' and domain before the '@'
    # giving `me-you=example.com@example.com`
    def return_path=(email_address)
      if (!!options.fetch(:verp) { MailTools::Config.verp })
        email_address  = email_address.sub(/@/, '-@') if email_address =~ /\w@/
        email_address += '-@[]'
      end
      @return_path     = email_address
    end

    # Reads the message from the IO stream passed (such as $stdin)
    def read_message(io)
      @message = io.read
    end

    def load_mailfile(filename)
      m                = MailTools::Maildrop.mailfile(filename)
      self.message     = m.message
      self.return_path = m.return_path
      self.recipients  = m.recipients
      self.options     = m.options
    end

    def use_headers(replace_headers=true)
      h = message_headers
      if !self.return_path || self.return_path.empty? || replace_headers
        self.return_path = addresses(h[:from]).first
      end

      recips =  []
      [:to, :cc, :bcc].each do |hdr|
        recips << addresses(h[hdr])
      end
      if !self.recipients || self.recipients.empty? || replace_headers
        self.recipients = recips.flatten
      end

      remove_bcc_header
    end

    def message_headers
      head, _   = self.message.split(/\n\s*\n/,2)
      headlines = head.split(/\n(?=\w)/s)
      headers   = {}
      headlines.each do |h|
        n,v = h.chomp.split(/:\s*/, 2)
        headers[n.downcase.gsub(/\W/, '_').to_sym] = v.gsub(/\n\s*/, ' ')
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
    # MailTools::Result Object with the response.
    def sendmail(method=nil, &block)
      if block
        block.call(self)
      elsif self.options[:method].respond_to?(:sendmail)
        self.options[:method].sendmail(self)
      elsif self.options[:method].is_a?(Proc)
        self.options[:method].call(self)
      else
        raise "Unknown mailing method"
      end
    end

    def recipient_file(filename)
      File.readlines(filename).each do |rec|
        self.recipients.push($1) if rec =~ /\A\s*(\S+@\S)/
      end
    end

    # Build netstring of messagebody+returnpath+recipient...
    def to_netstring
      nstr  = MailTools::Netstring.encode(self.message+"\n")
      nstr += MailTools::Netstring.encode(self.return_path)
      self.recipients.each { |r| nstr += MailTools::Netstring.encode(r) }
      MailTools::Netstring.encode(nstr)
    end

    # Instantiate a message from a message qmqp netstring
    def self.from_netstring(netstring)
      qmqp_msg, _ = Netstring.decode(netstring)
      body, rp, *recip = MailTools::Netstring::decode_list(qmqp_msg)
      new(body, rp, recip)
    end

    def to_md5
      Digest::MD5.hexdigest(self.message + self.return_path +
                            self.recipients.join(' '))
    end

    def to_json
      {message:self.message, return_path:self.return_path,
       recipients:self.recipients}.to_json
    end

    def self.from_json(json_string)
      o = JSON.parse(json_string)
      new(o["message"], o["return_path"], o["recipients"])
    end

    def to_s
      [self.return_path, *self.recipients, "", self.message].join("\n")
    end

    # Returns in instance of the message created with the to_s format
    def self.from_string(s)
      envelope, message = s.split("\n\n", 2)
      return_path, *recipients = envelope.split("\n")
      new(message, return_path, recipients)
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
