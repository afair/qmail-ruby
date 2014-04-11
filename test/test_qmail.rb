require_relative 'test_helper'

class TestQmail

  def test_queue
    m = Qmail.sendmail('Subject', 'from@example.com', 'recip@example.com')
    p m.inspect
    assert_equal "Subjectx", m.message
  end

end
