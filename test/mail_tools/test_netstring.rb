require_relative '../test_helper'

class TestNetstring < MiniTest::Test

  def test_encode
    s = MailTools::Netstring.encode("abc")
    assert_equal "3:abc,", s
  end

  def test_decode
    s, _ = MailTools::Netstring.decode("3:abc,")
    assert_equal "abc", s
  end

  def test_decode_msg
    qmqp_string = "19:3:msg,2:rp,5:recip,,"
    msg, _ = MailTools::Netstring.decode(qmqp_string)
    body, rp, *recip = MailTools::Netstring::decode_list(msg)
    assert_equal "msg", body
    assert_equal "rp", rp
    assert_equal "recip", recip.first
  end

end
