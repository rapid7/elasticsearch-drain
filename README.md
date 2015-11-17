# Elasticsearch Drain

The purpose of this utility is to drain documents from Elasticsearch nodes in an AutoScaling Group.

This will help you do Elasticsearch node replacement while keeping the cluster healthy.  This is useful if you want to change the instance type of your nodes, or if you use custom AMIs and need to rollout a new AMI.

Consider the following deployment procedure:
 * Start with an AutoScaling Group with Elasticsearch nodes in a cluster
 * Create a new AutoScaling Group with Elasticsearch nodes that join the above cluster
 * Drain all data off older AutoScaling Group and remove instances from the AutoScaling Group and terminate instances


## How does it work?
1. Get the list of instances we want to remove from the cluster
  * In this case it's an entire AutoScaling Group
2. Ask the cluster for the `_id`(s) of those instances
3. Then, tell the cluster to exclude these nodes from routing, which effectively removes all documents from the nodes
4. Loop on these nodes asking the cluster how many documents each node is storing, when one reaches 0 we move on to the next step
5. Remove the instance from the AutoScaling Group
6. Terminate the instance
7. Wait a moment and go back to step 4 and continue until there are 0 instances in the AutoScaling Group


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

## What's next?
 * Remove a single node from the cluster
 * Drain only mode


## Testing
Install all dependencies:
```bash
gem install bundler
bundle install
```

To enable the tests that will hit the AWS APIs pass `ALLOW_DISABLED_VCR=true`

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
