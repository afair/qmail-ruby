require_relative '../test_helper.rb'

class TestMessage < MiniTest::Test
  def test_initialize
    m = basic_message
    assert_match(/Subject/, m.message)
    assert_equal 'me@example.com', m.return_path
    assert_equal 'you@example.com', m.recipients.first
    assert_equal :queue, m.options[:method]
  end

  def test_string_conversions
    m = basic_message
    assert_match(/\A[\da-f]{32}\z/, m.to_md5)
    assert_match(/\A113:72:Subject/, m.to_netstring)
    assert_match(/\A{\"message\":\"Subject/, m.to_json)
  end

  def test_use_headers
    email = basic_email.sub(/To:/, "Bcc: <secret@example.com>\nTo:")
    m = Qmail::Message.new(email, headers:true)
    assert_equal 'me@example.com', m.return_path
    assert_equal 'you@example.com', m.recipients.first
    assert_equal 'secret@example.com', m.recipients[1]
    refute_match(/Bcc:/, m.message)
  end

  def test_verp
    m = basic_message(nil, nil, verp:true)
    assert_equal 'me-@example.com-@[]', m.return_path
  end
end
