# Elasticsearch::Drain

The purpose of this script is to drain an existing ASG with ES nodes that are part of a single cluster.

Consider the following deployment procecture:
 * Start with an ASG with ES nodes in a cluster
 * Create a new ASG with ES nodes that join the above
 * Drain all data off first(old) ASG and remove instances from ASG and terminate

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elasticsearch-drain'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elasticsearch-drain

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/elasticsearch-drain/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
