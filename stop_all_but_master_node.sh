#!/bin/bash

SSH_OPT="-o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null"

function stop_api_if_not_master() {
  ip -br -c a s | grep -q `sudo ovs-vsctl get Open_Vswitch . external_ids:ovn-remote | cut -d':' -f 2`
  if [ $? = 0 ]; then
    echo "This is master node"
  else
    echo "Not a master node, stoping"
    sudo systemctl stop tripleo_neutron_api
  fi
}

for i in `seq 0 2`; do
  echo "Setting controller-$i"
  typeset -f stop_api_if_not_master | ssh $SSH_OPT controller-$i.ctlplane "$(cat); stop_api_if_not_master"
done

