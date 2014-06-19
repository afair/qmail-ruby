require_relative '../test_helper.rb'

class TestQMQP < MiniTest::Test

  def run_qmqp_server
    server = TCPServer.new(Qmail::Config.qmqp_port)
    Thread.new do
      client = server.accept
      b = 0
      while (ch = client.read(1)) =~ /\d/
        b = b * 10 + (ch.to_i - '0'.to_i)
      end
      msg = client.read(b)
      if msg =~ /\A\d+:Subject: Testing/
        client.puts Qmail::Netstring.of("Kok 1182362995 qp 21894")
      else
        client.puts Qmail::Netstring.of("Derror bad format")
      end
      client.close
    end
  end

  def test_qmqp
    Qmail::Config.qmqp_port = 6280
    run_qmqp_server
    r = Qmail::QMQP.sendmail(basic_message)
    p r unless r.succeeded?
    assert r.succeeded?, "Unsuccessful"
    assert "21894", r.qp
  end

end
