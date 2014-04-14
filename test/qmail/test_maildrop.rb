require_relative '../test_helper.rb'

class TestMaildrop < MiniTest::Test

  def test_drop
    r = Qmail::Maildrop.sendmail(basic_message, MAILDROP_DIR)
    assert r.succeeded?
    assert File.exist?(r.info.first)
    f = File.readlines(r.info.first)
    assert_match(/\AMailfile/, f[0])
    assert_equal "me@example.com", f[1].chomp
    assert_equal "you@example.com", f[2].chomp
    assert_match(/\ASubject/, f[4])
  end

  def test_pickup
    m = basic_message
    d = maildrop
    r= d.sendmail(m)
    m2 = nil
    d.pickup { |msgin| m2 = msgin; true }
    assert_equal m.to_s, m2.to_s
    assert !File.exist?(r.info.join(File::SEPARATOR))
  end
end
