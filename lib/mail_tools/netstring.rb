module MailTools

  # Returns the Netstring of the given string. It is defined at:
  #   http://cr.yp.to/proto/netstrings.txt
  # and is encoded as "<LENGTH>:<VALUE>,"
  #
  # Usage:
  #
  #   MailTools::Netstring.of("mail_tools") #=> "5:mail_tools,"
  #
  # The Netstring is used mainly in QMQP Communications to encode
  # the message and envelope as:
  #
  #  netstring(netstring(messagebody) + netstring(returnpath)
  #            + netstring(recipient) + ...)
  #
  # Since MailTools/SMTP is 7-bit only, this string is expected to be
  # a 7-bit ASCII. Unpredictable results will occur if you send
  # UTF-8 (Unicode) or 8-bit extensions (ISP-8851-x).

  class Netstring

    # Encodes the given string as a netstring
    def self.encode(str)
       "#{str.size}:#{str},"
    end

    # Takes a netstring, returns a pair of the [string, remainder]
    # returns nil on a bad netstring format
    def self.decode(netstring)
      len = netstring.to_i
      if netstring && netstring =~ /\A\d+:(.{#{len}}),(.*)/m
        [$1, $2]
      else
        nil # bad String
      end
    end

    # Take a string containing concatenated netstrings, return array of
    # decoded strings
    def self.decode_list(list)
      strings = []
      while list
        s, list = decode(list)
        strings << s if s
      end
      strings
    end
  end
end
