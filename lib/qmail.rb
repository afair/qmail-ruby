require "qmail/version"
require "qmail/message"
require "qmail/netstring"
require "qmail/inject"
require "qmail/smtp"
require "qmail/qmqp"
require "qmail/qmail_queue"

# The Qmail module implements Qmail interation functions, usually as a client.
# It is not intended to replace the full MTA.
module Qmail

  # Queues the message with the given envelope (return path and recipients)
  # to the local qmail system, or remote system with the proper options.
  #
  # Usage:
  #   Qmail.sendmail(message, return_path, recipients, options)
  #      message     - String of Message Data (Headers + Bodies)
  #      return_path - email address to which undelivered email reports will be sent.
  #      recipients  - An list or array of email addresses
  #      options     - A hash of directives to control the queueing.
  #
  # Options:
  #      method: "queue|qmqp|smtp|maildrop" 
  #        - Sends the qmail using one of these commands adhering to qmail-queue
  #      ip: "127.0.0.1"
  #      port: 630
  #        - Ip address and port for QMQP (630) or SMTP (25) Communication
  #        - qmail-qmqpc takes its default ip address from qmail/controls/qmqpservers.
  #      recipient_file: "/path/file"
  #        - If specified, it adds recipient addresses, one per line, from that file. 
  #      headers: true
  #        - Loads return path from message From header, recipients from To, CC, Bcc
  #          headers. It will then delete the Bcc header from the message.
  #      mailfile: "/path/file"
  #        - Loads message and evelope from the mailfile, constructed as:
  #              Mailfile --option value --option value ... (optional line)
  #              returnpath@example.com
  #              recipient1@example.com
  #              ...(remaining recipients, followed by blank line)
  #
  #              Message Data (Headers and Bodies as sent in the SMTP DATA command)
  #      qmail_root: "dir"
  #        - Directory where qmail is deployed (usually /var/qmail)
  #      qmail_queue: "programfile"
  #        - Alternate location for a program speaking the qmail-queue protocol
  #      logger: loggerobject
  #        - Logs messages here if specified
  #      maildrop_dir: dirname
  #        - Directory for maildrop operations. Failed sendmails can also be
  #          archived here for retry processing.
  #   
  def sendmail(message, return_path=nil, recipients=[], *args)
    @qmessage = Qmail::Message.new(message, return_path=nil, recipients=[], *args)
    @qmessage.sendmail
  end

  def maildrop(dir, *args)
    @qmessage = Qmail::Message.new(*args)
    @qmessage.maildrop(dir)
  end


  ERRORS = {
    -1 => "Unknown Error",
    0  => "Success",
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

end
