require_relative 'test_helper'

class TestQmail < MiniTest::Test

  def test_sendmail
    m = Qmail::sendmail(basic_email, 'me@example.com', 'you@example.com')
    p m.inspect
    assert_equal true, m.failed?
  end

end
