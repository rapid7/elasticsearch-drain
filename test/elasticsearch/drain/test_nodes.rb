require 'test_helper'
require 'pp'

class TestNodes < Minitest::Test
  def setup
    VCR.insert_cassette 'nodes'
    @nodes = ::Elasticsearch::Drain::Nodes.new('localhost:9250')
  end

  def teardown
    VCR.eject_cassette
  end

  def test_has_nodes
    assert_respond_to @nodes, :client
  end

  def test_nodes_is_array
    assert_respond_to @nodes.nodes, :each
  end

  def test_bytes_stored
    node = @nodes.info['nodes'].first[0]
    bytes_stored = @nodes.bytes_stored(node)
    assert_respond_to bytes_stored, :+
  end

  def test_asg
    assert_respond_to @nodes, :asg
  end

  def test_region
    assert_respond_to @nodes, :region
  end

end
#   #
#   # function drain_docs_from_node() {
#   #     curl -XPUT $CLUSTER_HOST/_cluster/settings -d "{ \"transient\" : { \"cluster.routing.allocation.exclude._ip\" : \"$NODES\" }}"
#   #     echo
#   # }
#   #
#   # function bytes_stored_on_node() {
#   #     NODE=$1
#   #     bytes=$(curl -s $CLUSTER_HOST/_nodes/$NODE/stats/indices | jq --raw-output '.nodes[].indices.store.size_in_bytes')
#   #     return $bytes
#   # }
#
#   def test_nodes_in_recovery
#     skip("NYI")
#     assert_respond_to @drain.recovery :each
#   end
#   # function node_in_recovery() {
#   #     curl -s "$CLUSTER_HOST/_cat/recovery?active_only=true&v=true" | grep $NODE
#   #     recovery_status=$?
#   #     return $recovery_status
#   # }
#   #
#   # function sleep_time() {
#   #   BYTES=$1
#   #
#   #   if (($BYTES >= 10000000000)); then
#   #       sleep_time=120
#   #   elif (($BYTES >= 1000000)); then
#   #       sleep_time=60
#   #   elif (($BYTES >= 100,000)); then
#   #       sleep_time=30
#   #   fi
#   #
#   #   return $sleep_time
#   # }
#   #
#   # function set_asg_min_size() {
#   #     echo "Setting $ASG_NAME AutoScalingGroup to a MinSize of 0"
#   #     aws --region $REGION autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --min-size 0
#   # }
#   #
#   # function remove_instance_from_asg() {
#   #     echo "Removing $INSTANCE_ID from $ASG_NAME AutoScalingGroup"
#   #     aws --region $REGION autoscaling detach-instances --instance-ids $INSTANCE_ID --auto-scaling-group-name $ASG_NAME --should-decrement-desired-capacity
#   # }
#   #
#   # function terminate_instance() {
#   #     echo "Terminating $INSTANCE_ID"
#   #     aws --region $REGION ec2 terminate-instances --instance-ids $INSTANCE_ID
#   # }
#   #
#   # function cluster_health() {
#   #     HEALTH=$(curl -s $CLUSTER_HOST/_cluster/health | jq --raw-output '.status')
#   #     if [ "$HEALTH" != "green" ]; then
#   #         echo "Cluster is not healthy, aborting"
#   #         echo "Current cluster health is $HEALTH"
#   #         exit 1
#   #     fi
#   #     echo "Cluster health is $HEALTH"
#   # }
#   #
#   # function get_nodes_in_asg() {
#   #     INSTANCES=$(aws --region $REGION autoscaling describe-auto-scaling-instances | jq --raw-output \
#   #         ".AutoScalingInstances[] | select(.AutoScalingGroupName == \"$ASG_NAME\" and .LifecycleState == \"InService\") | .InstanceId")
#   # }
#   #
#   # function get_node_ipaddress() {
#   #     IP=$(aws --region $REGION ec2 describe-instances --instance-ids $i | jq --raw-output \
#   #         '.Reservations[].Instances[0].PrivateIpAddress')
#   # }
#   #
#   # function remove_node_from_cluster() {
#   #     drain_docs_from_node
#   #     bytes_stored_on_node $NODE
#   #
#   #     #while [ "$bytes" != "0" ]; do
#   #     #    echo "Waiting for $bytes bytes to drain off $NODE"
#   #     #    sleep_time $bytes
#   #     #    sleep $sleep_time
#   #     #    bytes_stored_on_node $NODE
#   #     #done
#   #
#   #     node_in_recovery $NODE
#   #     while [ "$recovery_status" == "0" ]; do
#   #         echo "Waiting for all recoveries on $NODE to finish"
#   #         sleep 10
#   #         node_in_recovery $NODE
#   #     done
#   #
#   #     cluster_health
#   #     remove_instance_from_asg
#   #     cluster_health
#   #     sleep 10
#   #     cluster_health
#   #     terminate_instance
#   #     cluster_health
#   # }
#   #
#   # function usage() {
#   #   echo "Usage: $0 REGION ASG_NAME CLUSTER_HOST"
#   # }
#   #
#   # if [ -z "$ASG_NAME" ]; then
#   #     echo "ASG_NAME is missing"
#   #     usage
#   #     exit 1
#   # fi
#   #
#   # if [ -z "$REGION" ]; then
#   #     echo "REGION is missing"
#   #     usage
#   #     exit 1
#   # fi
#   #
#   # if [ -z "$CLUSTER_HOST" ]; then
#   #     echo "CLUSTER_HOST is missing"
#   #     usage
#   #     exit 1
#   # fi
#   #
#   # cluster_health
#   # get_nodes_in_asg
#   # echo "Found nodes in ASG: $INSTANCES"
#   #
#   # cluster_health
#   # set_asg_min_size
#   #
#   # for i in $INSTANCES; do
#   #     get_node_ipaddress
#   #     NODE=$IP
#   #     NODES+="${NODE},"
#   # done
#   # NODES=${NODES%?}
#   #
#   # echo "Sleeping 1 minute before starting"
#   # sleep 60
#   # echo "Draining data from $NODES"
#   #
#   # for i in $INSTANCES; do
#   #     get_node_ipaddress
#   #     INSTANCE_ID=$i
#   #     NODE=$IP
#   #     echo "Removing $NODE from ES cluster and $ASG_NAME AutoScalingGroup"
#   #     cluster_health
#   #     remove_node_from_cluster
#   #     cluster_health
#   #     echo "Sleeping for 1 minute before removing the next node"
#   #     sleep 60
#   # done
# end
