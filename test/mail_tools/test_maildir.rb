require_relative '../test_helper.rb'

class TestMaildir < MiniTest::Test

  def test_deliver
    maildir = "/tmp/maildir.test"
    MailTools::Maildir.new(maildir).clean!
    fname = MailTools::Maildir.deliver(basic_message, maildir)
    assert File.exist?(fname)
    f = File.read(fname)
    assert f =~ /\AReturn-Path: <me@example\.com>/, "From line"
    assert f =~ /Delivered-To: you@example.com/m, "Delivered-To"
    assert f =~ /Subject: Testing/m, "Message Body"
    MailTools::Maildir.new(maildir).kill!
  end

  def test_receive
    maildir = "/tmp/maildir.test"
    MailTools::Maildir.new(maildir).clean!
    mdir = MailTools::Maildir.new(maildir)
    mdir.deliver(basic_message)
    mdir.deliver(basic_message)

    msgs = []
    mdir.receive {|m, fn| msgs << m }
    assert_equal 2, msgs.size
    assert_match(/Subject/m, msgs.first.message)
    MailTools::Maildir.new(maildir).kill!
  end
end
