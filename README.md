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

## Contributing

1. Fork it ( https://github.com/rapid7/elasticsearch-drain/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
