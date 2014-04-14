require_relative '../test_helper.rb'

class TestQMQP < MiniTest::Test

  def test_qmqp
    r = Qmail::QMQP.sendmail(basic_message)
    p r
    assert r.succeeded?, "Unsuccessful"
  end

end
