require_relative '../test_helper.rb'

class TestSMTP < MiniTest::Test

  class SMTPTester
    def self.start(recip_host, port, helo_host)
      @messae = nil
      yield self
    end

    def self.send_message(*args)
      @message = args
    end

    def self.sent
      @message
    end
  end

  def test_smtp
    m = basic_message
    MailTools::Config.smtp_class = SMTPTester
    MailTools::SMTP.sendmail(m)
    assert_equal m.recipients.first, SMTPTester.sent[2]
  end

end
