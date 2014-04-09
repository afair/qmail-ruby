module Qmail

  # Returns the Netstring of the given string. It is defined at:
  #   http://cr.yp.to/proto/netstrings.txt
  # and is encoded as "<LENGTH>:<VALUE>,"
  #
  # Usage:
  #
  #   Qmail::Netstring.of("qmail") #=> "5:qmail,"
  #
  # The Netstring is used mainly in QMQP Communications to encode
  # the message and envelope as:
  #
  #  netstring(netstring(messagebody) + netstring(returnpath)
  #            + netstring(recipient) + ...)
  #
  # Since Qmail/SMTP is 7-bit only, this string is expected to be
  # a 7-bit ASCII. Unpredictable results will occur if you send
  # UTF-8 (Unicode) or 8-bit extensions (ISP-8851-x).

  class Netstring
    def self.of(str)
       "#{str.size}:#{str},"
    end
  end
end
