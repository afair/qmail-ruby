require 'net/smtp'

module MailTools

  # Sends Email via SMTP using the qmail-remote command
  # Usage:
  #   MailTools::Qmail::SMTP.sendmail(mail_tools_message)
  #
  #   - mail_tools_message is MailTools::Message.new(message, return_path, recipients, options)
  #
  class SMTP

    def sendmail
      @qmsg.recipients.each do |r|
        _, recip_host = r.split(/@/,2)
        Net::SMTP.start(recip_host, 25) do |smtp|
          smtp.send_message(@qmsg.message, @qmsg.return_path, r)
        end
      end
    end

  end
end
