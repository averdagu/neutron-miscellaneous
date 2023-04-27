#!/bin/bash

packages="gpm-libs vim-filesystem vim-common vim"

mkdir -p /tmp/vim-dependencies
cd /tmp/vim-dependencies

for p in $packages; do
    dnf download $p
done

packages="gpm-libs vim-filesystem vim-common vim-enhanced"

for p in $packages; do
    for item in `ls /tmp/vim-dependencies | grep -v i686 | grep $p`; do
        podman cp $item neutron_api:/
        podman exec -uroot -ti neutron_api rpm -i $item
    done
done
