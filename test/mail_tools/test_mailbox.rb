require_relative '../test_helper.rb'

class TestMailbox < MiniTest::Test

  def test_mail
    mailbox = "/tmp/Mailbox.test"
    File.unlink(mailbox) if File.exists?(mailbox)
    MailTools::Mailbox.mail(basic_message, mailbox)
    assert File.exist?(mailbox)
    f = File.read(mailbox)
    assert f =~ /\AFrom me@example.com/, "From line"
    assert f =~ /Delivered-To: you@example.com/m, "Delivered-To"
    assert f =~ /Subject: Testing/m, "Message Body"
    File.unlink(mailbox) if File.exists?(mailbox)
  end

  def test_each
    mailbox = "/tmp/Mailbox.test"
    File.unlink(mailbox) if File.exists?(mailbox)
    MailTools::Mailbox.mail(basic_message, mailbox)
    MailTools::Mailbox.mail(basic_message, mailbox)

    box = MailTools::Mailbox.new(mailbox)
    assert_equal 2, box.count
    # Huh? .first returns an array below in test, not in irb. why?
    assert_match(/Subject/m, box.first.first.message)
    File.unlink(mailbox) if File.exists?(mailbox)
  end
end
