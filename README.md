# Logging::OddEven

Adds different colors depending on even or odd lines.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'logging-odd_even'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logging-odd_even

## Usage

Color the lines:
```
Logging.color_scheme('bright',
                      :lines => {
                           :debug => :white,
                           :debug_bright => :white_bright,
                           :info => :green,
                           :info_bright => :green_bright,
                           :warn => :yellow,
                           :warn_bright => :yellow_bright,
                           :error => :red,
                           :error_bright => :red_bright,
                           :fatal => [:white, :on_red],
                           :fatal_bright => [:white_bright, :on_red_bright]
                       },
                       :date => :white,
                       :date_bright => :white_bright,
                       :logger => :cyan,
                       :logger_bright => :cyan_bright,
                       :message => :magenta,
                       :message_bright => :magenta_bright
                       )
```
or just the log levels:
```
Logging.color_scheme('bright',
                       :levels => {
                            :debug => :white,
                            :debug_bright => :white_bright,
                            :info => :green,
                            :info_bright => :green_bright,
                            :warn => :yellow,
                            :warn_bright => :yellow_bright,
                            :error => :red,
                            :error_bright => :red_bright,
                            :fatal => [:white, :on_red],
                            :fatal_bright => [:white_bright, :on_red_bright]
                       },
                       :date => :white,
                       :date_bright => :white_bright,
                       :logger => :cyan,
                       :logger_bright => :cyan_bright,
                       :message => :magenta,
                       :message_bright => :magenta_bright

  )

Logging.appenders.stdout('stdout',
                           :auto_flushing => true,
                           :layout => Logging.layouts.even_odd_pattern(:pattern => "[%d] %x %T %-5l %c: %m\n",
                                                                       :color_scheme => 'bright')
  )
```

Start logging to standard out.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/logging-odd_even/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
