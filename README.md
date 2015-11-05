# Elasticsearch Drain

The purpose of this utility is to drain documents from Elasticsearch nodes in an AutoScaling Group.

This will help you do Elasticsearch node replacement while keeping the cluster healthy.

Consider the following deployment procedure:
 * Start with an AutoScaling Group with Elasticsearch nodes in a cluster
 * Create a new AutoScaling Group with Elasticsearch nodes that join the above cluster
 * Drain all data off older AutoScaling Group and remove instances from the AutoScaling Group and terminate instances

## Installation
```bash
$ gem install elasticsearch-drain
```

## Usage

1. Create a new AutoScaling Group and populate with the same number of instances as the previous AutoScaling Group
2. Run the tool, to start draining:
```bash
$ drain asg --asg="test-asg-0" --region="us-east-1" --host="localhost:9200"
```

## Testing
Install all dependencies:
```bash
gem install bundler
bundle install
```

Run test tests (unit and style):
```bash
rake
```
Or on a tight loop with guard:
```bash
bundle exec guard
```

If you need to make a new http request or refresh the fixtures you will need to start a test cluster.

By default the test cluster install is version `1.7.2`, this can be changed by setting the `ES_VERSION` enviroment variable.

Install and Start the Cluster:
```bash
rake elasticsearch:install elasticsearch:start
```

Run the tests:
```bash
rake test
```

Stop the Cluster:
```bash
rake elasticsearch:stop
```

And, to wrap all that up:
```bash
rake refresh_fixtures
```



## Contributing

1. Fork it ( https://github.com/rapid7/elasticsearch-drain/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
