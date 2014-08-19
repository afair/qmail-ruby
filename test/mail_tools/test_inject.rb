require_relative '../test_helper.rb'

class TestHTTP < MiniTest::Test

  def test_inject
    unless File.exists?(MailTools::Config.qmail_queue)
      interp = `which ruby`.chomp
      raise "oops"
      MailTools::Config.mail_tools_queue = "#{interp} ./test/qmail-queue.rb"
    end
    r = MailTools::Inject.sendmail(basic_message)
    p r unless r.succeeded?
    assert r.succeeded?, "Inject Unsuccessful :-("
    j = JSON.parse(r.info.first)
    assert_equal ENV['FROM']||"me@example.com", j["request"]["return_path"]
    #r = MailTools::Inject.sendmail(basic_message)
    #assert r.succeeded?, "Inject Unsuccessful :-("
  end
end
