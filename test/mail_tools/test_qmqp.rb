require_relative '../test_helper.rb'

class TestQMQP < MiniTest::Test

  def run_qmqp_server
    @qmqpmsg = nil
    Thread.new do
      MailTools::QMQP.server(6280, 1) do |msg|
        @qmqpmsg = msg
      end
    end
  end

  def test_qmqp
    m = basic_message
    MailTools::Config.qmqp_port = 6280
    run_qmqp_server
    r = MailTools::QMQP.deliver(m)
    p r unless r.succeeded?
    assert r.succeeded?, "Unsuccessful"
    p @qmqpmsg
    assert_equal m.message, @qmqpmsg.message.chomp # qmqp adds \n
  end

end
