#!/bin/bash
. overcloudrc

DELETE=0

while getopts 'd' OPTION; do
  case $OPTION in
    d)
      DELETE=1
      ;;
  esac
done

if [[ $DELETE == 1 ]]; then
  openstack server delete trunkvm
  openstack network trunk delete trunk
  openstack port delete trunkport
  openstack security group delete trunksec
  openstack router remove subnet trunkr trunksub
  openstack router delete trunkr
  openstack subnet delete trunksub

else
  openstack security group list | grep -q 'trunksec'
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "Creating security group"
    openstack security group create trunksec
    openstack security group rule create --protocol icmp trunksec
    openstack security group rule create --protocol tcp trunksec
  fi

  openstack network list | grep -q 'trunknet'
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "Creating network"
    openstack network create trunknet
  fi

  openstack subnet list | grep -q 'trunksub'
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "Creating subnet"
    openstack subnet create trunksub --subnet-range 192.110.1.0/24 --network trunknet
  fi

  openstack router list | grep -q 'trunkr'
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "Creating router"
    openstack router create trunkr
    openstack router add subnet trunkr trunksub
    openstack router set --external-gateway nova trunkr
  fi

  openstack port list | grep -q 'trunkport'
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "Creating port"
    openstack port create --network trunknet --security-group trunksec trunkport
    openstack port create --network trunknet --security-group trunksec trunksub
  fi

  openstack network trunk list | grep -q 'trunk'
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "Creating network trunk"
    openstack network trunk create --parent-port trunkport --subport port=trunksub,segmentation-type=vlan,segmentation-id=42 trunk
  fi

  openstack server list | grep -q 'trunkvm'
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "Creating server"
    openstack server create --image cirros-0.5.2-x86_64-disk.img --flavor m1.micro --nic port-id=trunkport trunkvm
  fi
fi

