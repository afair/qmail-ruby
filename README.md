# The Qmail Gem

The Qmail Gem
implements direct interfaces to the
[Qmail](http://qmail.org) mail server (MTA).
Use it to insert an email message into the Qmail queue and other
operations.

This library supersedes the original [ruby-qmail](https://github.com/afair/ruby-qmail])
library and `ruby-qmail` gem.

## Installation

Add this line to your application's Gemfile:

    gem 'qmail'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qmail

## Usage

If you are not using a Gemfile, remember to require the gem

```ruby
require "qmail"
```

### Configuration

To specify global options for Qmail processing, override them like this:

```ruby
Qmail::Config do |q|
  q.method = :queue || :qmqp || :maildrop
  q.maildrop_dir = "/var/maildrop"
  q.ip = "127.0.0.1" # For qmqp
  q.port = 628       # For qmqp
  q.qmail_dir = "/var/qmail"
  q.logger = Logger.new() # Or Your rails logger
end
```

In rails, this may be in a `./config/initializers/qmail.rb` file.

### Sending Email

```ruby
message = Mail.new().to_s
result = Qmail.sendmail(message, "returnpath@example.com", "recipient@example.com")
```

By default, this invokes `qmail-queue` to write the message and envelope into the
qmail queue on the local host.

To send email with the addresses in the email headers, do:

```ruby
result = Qmail.sendmail(message, headers:true)
```

The return path will be set by the From header, and recipients set by the To,
CC, and Bcc headers. The Bcc header will be deleted.

### QMQP

To send by [QMQP](http://cr.yp.to/proto/qmqp.html),
specify the method option of :qmqp. QMQP is
useful to transfer the message to another server for delivery quickly instead of
relaying through SMTP, which is far slower. Optionally, specify  `ip:"127.0.0.1"`
and `port:628` as well to override the Qmail default ones.

```ruby
result = Qmail.sendmail(message, "returnpath@example.com",
                        ["recipient@example.com", "recipient@example.com"],
                        method: :qmqp)
```

Postfix ships with a QMQP module and can accept mail with this method.

### SMTP

Sending mail via SMTP is also provided, but not recommended for standard processing.
This invokes the `qmail-remote` program to perform the sending. To use, specify
the method of :smtp.

### Maildrop

This library supplies a Maildrop service for offline and retry mailings. This is
useful when you can't rely on the network always being available.

Messages are serialized into the maildrop directory in `Mailfile` format:

```
Mailfile --option=value ... [Optional line]
returnpath@example.com
recipient1@example.com
...                         [Other recipients]
                            [Blank line]
Subject: Hello, world!      [RFC822-formated headers and bodies]
...
```

And are named by the MD5 hash of the message envelope and data. (This also prevents
identical messages in the maildrop.)

Maildrop provides a pickup method that takes a block accepting a Qmail::Message
object to be processed. It should return true to delete the file after successful
processing, or false to leave it to retry later.

This is not meant to replace a mail queue, or message queue, but to provide an
interim place to store messages for processing in a related process.

Maildrop can be used without Qmail.

```ruby
result = Qmail.maildrop("/var/maildrop",
                        message, "returnpath@example.com",
                        ["recipient1@example.com", "recipient2@example.com"],
                        method: :maildrop)

# In another process, picked up the dropped mail
Qmail::Maildrop.new("/var/maildrop").pickup {|m| Qmail::Inejct.sendmail(m) }
```

Deferred messages in the maildrop have the number of times is has been attempted
appended to the file name (".1", ".2", etc.)

### Email to HTTP Gateway

Qmail is not required to use the HTTP Gateway, though this is designed to
operate from a qmail local delivery to a `.qmail` and/or `.qmail-default` file:

```
|/app_path/bin/qmail-http "http://example.com/email"
```

Qmail sets `SENDER` environment variable as the return path, and the `RECIPENT`
variable as the email address being delivered. It also sets other variables as
well, though these may be all you need to start.

STDIN contains the message. Your gateway script could be something like this.
You may want to specify the URL endpoint in a configuration elsewhere instead
of hard-coding within the dot-file or wrapper script.

```ruby
# /app_path/bin/qmail-http
require 'qmail'
url = ARGV.shift
result = Qmail.http(url
                    $stdin.read, ENV['SENDER'], ENV['RECIPIENT'],
                    http_headers: {}, json_extra: {})
```

The `http_headers` hash can be used to specify authorization headers. If `json_extra`
is defined, it will be merged into the data structure sent on the POST.

The message is POST'ed to the endpoint URL in JSON format. There will be only one
recipient, but the format matches the internal structures of the project.

```
POST http://example.com/email
Content-Type: application/json
Additional-Header: from the http_headers option

{ "returnPath":"returnpath@example.com",
  "recipients":["recipient1@example.com"],
  "message":"Subject: Hello, World!...",
  "extraField": "from the json_extra option"
}
```

## Future Plans

Pull Requests for these would be great!

### Qmail / ActionMailer Integration

Although it can respond to any "sendmail" command, it would be great to
offer a Maildrop or QMQP service as well.

### Qmail::Queue Class

* Queue Utilities and Searching

### Qmail::Log Class

* Parses Qmail Logs like qmail-analyze would do. 
* "grep" certain deliveries from the log
* Failure Analysis




## Contributing

1. Fork it http://github.com/afair/qmail/fork
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
