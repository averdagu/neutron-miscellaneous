#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
  echo "Ending monitoring logs"
  kill -9 $server_log_pid
  kill -9 $ovnnb_pid
  kill -9 $ovnsb_pid
  # Modify ownership of files
  chown cloud-admin:cloud-admin /tmp/server.log
  chown cloud-admin:cloud-admin /tmp/ovnnb_db.db
  chown cloud-admin:cloud-admin /tmp/ovnsb_db.db
  exit 0
}


if [ "$EUID" -ne 0 ]; then
  echo "Need to be run as root"
  exit 1
fi

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

while :; do sleep 10; done

