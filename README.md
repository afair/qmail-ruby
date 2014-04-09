# Qmail Gem

The Qmail Gem (originally
(ruby-qmail)[https://github.com/afair/ruby-qmail])) 
implements direct interfaces to the 
[Qmail][(http://qmail.org) mail server (MTA). 
Use it to insert an email message into the Qmail queue and other
operations.


## Installation

Add this line to your application's Gemfile:

    gem 'qmail'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qmail

## Usage

```ruby
  require 'qmail'
  result = Qmail.queue("returnpath@example.com", message, 'recipient@example.com")
  result = Qmail.qmqp("returnpath@example.com", message, 'recipient@example.com")
  result = Qmail.qmqp("returnpath@example.com", message, 'recipient@example.com",
                      method:'qmail-qmqpc', ip:ip_address, port:port)

  Qmail::Queue.new # 
  Qmail::Log.parse #
  Qmail::Log.parse.find {|log| log.recipient == r}

  Qmail::sendmail # sendmail interface to Qmail (used with binstub)
  Qmail::Remote # qmail-remote
  Qmail::Local # qmail-local
  
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/qmail/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
