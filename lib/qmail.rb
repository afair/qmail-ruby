require "qmail/version"
require "qmail/queue"

# The Qmail module implements Qmail interation functions, usually as a client.
# It is not intended to replace the full MTA.
module Qmail

  # Queues the message with the given envelope (return path and recipients)
  # to the local qmail system, or remote system with the proper options.
  #
  # Usage:
  #   Qmail.queue(message, return_path, recipients, options)
  #      message     - String of Message Data (Headers + Bodies)
  #      return_path - email address to which undelivered email reports will be sent.
  #      recipients  - An list or array of email addresses
  #      options     - A hash of directives to control the queueing.
  #
  # Options:
  #      method: "queue|qmqp|smtp|command" 
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
  #   
  def queue(message, return_path=nil, recipients=[], *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    recipients = Array(recipients) unless recipients.is_a?(Array)
    recipients.push(*args) if args.size > 0

    Qmail::Inject.queue(message, return_path, recipients, options)
  end

end
