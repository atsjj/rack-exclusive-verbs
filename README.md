# Rack::ExclusiveVerbs

Rack middleware implementing an IP whitelist of HTTP verbs.

## Usage:

```ruby
require 'rack/exclusive_verbs'

use Rack::ExclusiveVerbs do
  resolver { Socket.ip_address_list.select { |addr| addr.ipv4_private? }.collect(&:ip_address) } ## optional
  allow only: '10.0.0.1', to: [:put, :post]
  allow only: '10.0.0.1', to: :post
  allow only: '10.0.0.1', to: :be_safe ## get, head, options, trace
  allow only: '10.0.0.1', to: :be_unsafe ## delete, patch, post, put
  allow range: '10.0.0.0/24', to: [:put, :post]
  allow range: '10.0.0.0/24', to: :post
  allow range: '10.0.0.0/24', to: :be_safe ## get, head, options, trace
  allow range: '10.0.0.0/24', to: :be_unsafe ## delete, patch, post, put
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-exclusive-verbs'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-exclusive-verbs

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/atsjj/rack-exclusive-verbs )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
