require_relative '../test_helper.rb'

class TestHTTP < MiniTest::Test

  def test_http
    r = MailTools::HTTP.deliver(basic_message, "http://allenfair.com/ip/")
    assert r.succeeded?, "HTTP Unsuccessful :-("
    j = JSON.parse(r.info.first)
    assert_equal "me@example.com", j["request"]["return_path"]
  end

  def test_http_failure
    r = MailTools::HTTP.deliver(basic_message, "http://allenfair.com/ipbad/")
    assert r.failed?, "This request should fail"
  end
end
