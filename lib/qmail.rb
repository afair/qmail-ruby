require "qmail/config"
require "qmail/http"
require "qmail/inject"
require "qmail/maildrop"
require "qmail/message"
require "qmail/netstring"
require "qmail/qmqp"
require "qmail/result"
require "qmail/smtp"
require "qmail/version"

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
  # Returns: a Qmail::Result object
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
  def self.sendmail(*message_args)
    qmessage = Qmail::Message.new(*message_args)
    qmessage.sendmail
  end

  # Implements the basic Sendmail command line to send email
  #
  #     echo message | sendmail -f return_path recipients ...
  #
  # To use this way, invoke this command from the command line or shell script:
  #
  #     echo message | ruby -r qmail -e 'Qmail.command' return_path recipients...
  #
  # To use a shell script, you can also send options with default delivery method
  #
  # sendmail.sh:
  #     ruby -r qmail -e 'Qmail.command(method: :queue)' $*
  # (You may also want to use getops to parse -freturn_path and send it in properly)
  #
  def self.command(options={})
    (return_path, *recipients) = ARGV
    options[:mailhandle] ||= $stdin
    qmessage = Qmail::Message.new('', return_path, recipients, options)
    qmessage.sendmail
  end

  def self.maildrop(dir, *message_args)
    qmessage = Qmail::Message.new(*message_args)
    qmessage.maildrop(dir)
  end

  def self.log(level, *data)
    return unless Qmail::Config.logger
    Qmail::Config.logger.send(level, *data)
  end

  # These are process exit codes for Qmail delivery processing (see qmail-local)
  EXIT_ERROR           = 1..98
  EXIT_PERMANENT_ERROR = 11..40
  EXIT_STOP            = 99     # Stop further  processing, mark as done
  EXIT_DEFER           = 111    # Delivery Should Retry
  EXIT_OK              = 0      # Delivery successful

  DELIVERY_STATUS = {
    'k' => 0,                   # Success
    'd' => 1,                   # Failed or Queue Timeout
    'z' => EXIT_DEFER,          # Deferred, retry later
  }

  # These are Qmail queueing errors
  ERRORS = {
    0  => "Success",
    1  => "Unknown Error",
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
    74 => "Connection to mail server succeeded, but communication failed.",
    81 => "Internal bug; e.g., segmentation fault.",
    91 => "Envelope format error"
  }

end
