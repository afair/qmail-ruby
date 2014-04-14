require_relative '../test_helper.rb'

class TestHTTP < MiniTest::Test

  def test_inject
    unless File.exists?(Qmail::Config.qmail_queue)
      interp = `which ruby`.chomp
      Qmail::Config.qmail_queue = "#{interp} ./test/qmail-queue.rb"
    end
    r = Qmail::Inject.sendmail(basic_message)
    assert r.succeeded?, "Inject Unsuccessful :-("
  end
end
