#!/bin/bash

set -x

# Add existing DSE cluster to the OpsCenter
seed_node_dns=${SEED_DNS}
opsc_dns=${OPSC_DNS}
cluster_size=${CLUSTER_SIZE}
cluster_name=${CLUSTER_NAME}
opsc_admin_password=${OPSC_ADMIN_PASSWORD}
cluster_file=${CLUSTER_FILE:-/config.json}


# Get a session id for auth-access
sleep='20s'
while true;
do
  echo "Attempt to login ..."
  json=$(curl --retry 10 -k -s -X POST -d "{\"username\":\"admin\",\"password\":\"$opsc_admin_password\"}" https://$opsc_dns:8443/login)
  RET=$?

  if [[ $json == *"sessionid"* ]]; then
    echo "sessionid retrieved"
    break
  fi

  if [ $RET -eq 0 ]
  then
    echo -e "\nUnexpected response: $json"
    continue
  fi

  sleep $sleep
done
token=$(echo $json | tr -d '{} ' | awk -F':' {'print $2'} | tr -d '"')


# Add the DSE cluster to OPSC
if [ ! -f $cluster_file ]; then
    tee $cluster_file > /dev/null <<EOF
{ 
  "cassandra": {
    "seed_hosts": "$seed_node_dns"
  },
  "cassandra_metrics": {},
  "jmx": {
    "port": "7199"
  }
}
EOF
fi

output="temp"
while [ "${output}" != "\"${cluster_name}\"" ]; do
    output=`curl -s -k -H 'opscenter-session: '$token -H 'Accept: application/json' -X POST https://$opsc_dns:8443/cluster-configs -d @$cluster_file`
    echo $output
    sleep 5
done


# Ensure all the nodes are up (UN) before proceeding to next steps if CLUSTER_SIZE is defined
if [ ! -z "$CLUSTER_SIZE" ]; then
  output="not_ready"
  while [ "${output}" != "ready" ]; do
      nodes_json=`curl -s -k -H 'opscenter-session: '$token -H 'Accept: application/json' https://$opsc_dns:8443/$cluster_name/nodes/all/last_seen`
      output=`python all_nodes_up.py "$nodes_json" $cluster_size`
      echo $output
      sleep 5
  done
fi


# Alter system keyspaces to use NetworkTopologyStrategy and RF 3. 
# NOTE: excludes system, system_schema, dse_system & solr_admin.
release="7.0.3"
wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.tar.gz
tar -xvf $release.tar.gz
# Install extra OS packages
pushd install-datastax-ubuntu-$release/bin
./os/extra_packages.sh
popd

pushd install-datastax-ubuntu-$release/bin/lcm/
./alterKeyspaces.py --opsc-ip $opsc_dns --opscpw $opsc_admin_password
popd
