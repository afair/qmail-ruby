require_relative '../test_helper.rb'

class TestMessage < MiniTest::Test
  def test_initialize
    m = basic_message
    #m = Qmail::Message.new('Subject', 'returnpath@example.com', 'recipient@example.com', method: :queue)
    assert_match(/Subject/, m.message)
    assert_equal 'me@example.com', m.return_path
    assert_equal 'you@example.com', m.recipients.first
    assert_equal :queue, m.options[:method]
  end

  def test_string_conversions
    m = basic_message
    assert_equal "e1dae2239ae11f80a17231aefd44297d", m.to_md5
    assert_match(/\A113:72:Subject/, m.to_netstring)
    assert_match(/\A{\"message\":\"Subject/, m.to_json)
  end

  def test_use_headers
    m = basic_message(headers:true)
    assert_equal 'me@example.com', m.return_path
    assert_equal 'you@example.com', m.recipients.first
  end
end
