#!/bin/bash

. ~/overcloudrc

SERVER=ovn-migration-server-trunk-ext-pinger-2

current_compute=`openstack server list --long -c Host -c Name -f value | grep $SERVER | cut -d' ' -f2`

if [ "$current_compute" = "compute-0.redhat.local" ]; then
    next_compute="compute-1.redhat.local"
else
    next_compute="compute-0.redhat.local"
fi

echo "openstack server migrate --live-migration --host $next_compute --block-migration --wait $SERVER"
openstack server migrate --live-migration --host $next_compute --block-migration --wait $SERVER
