require 'getoptlong'
require 'socket'
require 'yaml'
require "mail_tools/config"
require "mail_tools/http"
require "mail_tools/mailbox"
require "mail_tools/maildir"
require "mail_tools/maildrop"
require "mail_tools/message"
require "mail_tools/netstring"
require "mail_tools/qmail/inject"
require "mail_tools/qmqp"
require "mail_tools/result"
require "mail_tools/smtp"
require "mail_tools/version"

# The MailTools module implements MailTools interation functions, usually as a client.
# It is not intended to replace the full MTA.
module MailTools

  # Queues the message with the given envelope (return path and recipients)
  # to the local mail_tools system, or remote system with the proper options.
  #
  # Usage:
  #   MailTools.mail(message, return_path, recipients, options)
  #      message     - String of Message Data (Headers + Bodies)
  #      return_path - email address to which undelivered email reports will be sent.
  #      recipients  - An list or array of email addresses
  #      options     - A hash of directives to control the queueing.
  #
  # Returns: a MailTools::Result object
  #
  # Options:
  #      method: "queue|qmqp|smtp|maildrop"
  #        - Sends the mail_tools using one of these commands adhering to mail_tools-queue
  #      ip: "127.0.0.1"
  #      port: 630
  #        - Ip address and port for QMQP (630) or SMTP (25) Communication
  #        - mail_tools-qmqpc takes its default ip address from mail_tools/controls/qmqpservers.
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
  #      mail_tools_root: "dir"
  #        - Directory where mail_tools is deployed (usually /var/mail_tools)
  #      mail_tools_queue: "programfile"
  #        - Alternate location for a program speaking the mail_tools-queue protocol
  #      logger: loggerobject
  #        - Logs messages here if specified
  #      maildrop_dir: dirname
  #        - Directory for maildrop operations. Failed mail can also be
  #          archived here for retry processing.
  #
  def self.mail(*message_args)
    qmessage = MailTools::Message.new(*message_args)
    qmessage.mail
  end


  def self.maildrop(dir, *message_args)
    qmessage = MailTools::Message.new(*message_args)
    qmessage.maildrop(dir)
  end

  def self.log(level, *data)
    return unless MailTools::Config.logger
    MailTools::Config.logger.send(level, *data)
  end

  # These are process exit codes for Qmail delivery processing (see mail_tools-local)
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

  # These are MailTools queueing errors
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
    61 => "Problem with the mail_tools home directory.",
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
