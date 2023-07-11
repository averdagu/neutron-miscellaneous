#!/bin/bash

trap ctrl_c INT

user="cloud-admin"
HOSTNAME=$(hostname)

function ctrl_c() {
  echo "Ending monitoring logs"
  # Modify ownership of files
  if [[ "$HOSTNAME" == "controller"* ]]; then
    kill -9 $server_log_pid
    kill -9 $ovnnb_pid
    kill -9 $ovnsb_pid
    chown $user:$user /tmp/server.log
    chown $user:$user /tmp/ovnnb_db.db
    chown $user:$user /tmp/ovnsb_db.db
  elif [[ "$HOSTNAME" == "compute"* ]]; then
    kill -9 $ovn_log_pid
    chown $user:$user /tmp/ovn-controller.log
  fi
  ovsdb-client dump > /tmp/post-db.log
  exit 0
}


if [ "$EUID" -ne 0 ]; then
  echo "Need to be run as root"
  exit 1
fi

ovsdb-client dump > /tmp/pre-db.log

if [[ "$HOSTNAME" == "controller"* ]]; then

  # server.log
  echo "Monitor server.log"
  tail -f /var/log/containers/neutron/server.log > /tmp/server.log &
  server_log_pid=$!
  echo $server_log_pid

  # ovn_nb.db
  echo "Monitor ovnnb_db.db in ovn_controller"
  path=`podman exec -uroot -ti ovn_controller find / -name ovnnb_db.db`
  podman exec -uroot -ti ovn_controller tail -f /run/ovn/ovnnb_db.db > /tmp/ovnnb_db.db &
  ovnnb_pid=$!
  echo $ovnnb_pid

  # ovn_sb.db
  echo "Monitor ovnsb_db.db in ovn_controller"
  path=`podman exec -uroot -ti ovn_controller find / -name ovnsb_db.db`
  podman exec -uroot -ti ovn_controller tail -f /run/ovn/ovnsb_db.db > /tmp/ovnsb_db.db &
  ovnsb_pid=$!
  echo $ovnsb_pid

elif [[ "$HOSTNAME" == "compute"* ]]; then
  # ovn-controller.log
  echo "Monitor server.log"
  tail -f /var/log/containers/openvswitch/ovn-controller.log > /tmp/ovn-controller.log &
  ovn_log_pid=$!
  echo $ovn_log_pid
fi

while :; do sleep 10; done

