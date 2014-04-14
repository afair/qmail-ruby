require_relative '../test_helper.rb'

class TestHTTP < MiniTest::Test

  def test_http
    r = Qmail::HTTP.sendmail(basic_message, "http://allenfair.com/ip/")
    assert r.succeeded?, "HTTP Unsuccessful :-("
    j = JSON.parse(r.info.first)
    assert_equal "me@example.com", j["request"]["return_path"]
  end

  def test_http_failure
    r = Qmail::HTTP.sendmail(basic_message, "http://allenfair.com/ipbad/")
    assert_match(/Not Found/, r.response)
  end
end
