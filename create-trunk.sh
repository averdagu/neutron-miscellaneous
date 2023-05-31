#!/bin/bash
. `find ~/ -name overcloudrc`

DELETE=0
FORCE=0
suffix_number=0
NUMBER=1

while getopts 'd:Dn:' OPTION; do
  case $OPTION in
    D)
      DELETE=1
      FORCE=1
      ;;
    d)
      # Needs to be the suffix number
      # TODO: Get full VM name and extract suffix
      DELETE=1
      name=$OPTARG
      ;;
    n)
      NUMBER=$OPTARG
      ;;
  esac
done

if [[ $DELETE == 1 ]]; then
  # Dinamic elements
  if [[ $FORCE == 1 ]]; then
    suffix_number=$(openstack server list -c Name -f value | grep trunkvm)
  elif [[ ! -z $name ]]; then
    suffix_number=$name
  fi
  echo "Deleting server"
  for s in $suffix_number; do
    openstack server delete trunkvm${s#trunkvm}
    echo "Deleting network"
    openstack network trunk delete trunk${s#trunkvm}
    echo "Deleting ports"
    openstack port delete trunkport${s#trunkvm}
    openstack port delete trunksub${s#trunkvm}
  done
  echo "Deleting router"
  openstack router remove subnet trunkr trunksub
  openstack router delete trunkr
  echo "Deleting sec group"
  openstack security group delete trunksec
  echo "Deleting subnet"
  openstack subnet delete trunksub

else
  # STATIC ELEMENTS
  if [[ ! -f cirros.img ]]; then
    curl -k -L http://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img > cirros.img
  fi
  openstack image list | grep -q 'trunkcirros'
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "Creating image"
    openstack image create trunkcirros --file cirros.img --disk-format qcow2 --container-format bare --public
  fi

  openstack flavor list | grep -q 'trunkflavor'
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "Creating flavor"
    openstack flavor create --disk 1 --ram 256 trunkflavor
  fi

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

  # Dinamic elements
  while [[ $suffix_number < $NUMBER ]]; do
    openstack port list | grep -q "trunkport${suffix_number}"
    rc=$?
    if [[ $rc != 0 ]]; then
      echo "Creating port"
      openstack port create --network trunknet --security-group trunksec trunkport${suffix_number}
      openstack port create --network trunknet --security-group trunksec trunksub${suffix_number}
    fi

    openstack network trunk list | grep -q "trunk${suffix_number}"
    rc=$?
    if [[ $rc != 0 ]]; then
      echo "Creating network trunk"
      seg_id=$((42+$suffix_number))
      openstack network trunk create --parent-port trunkport${suffix_number} --subport port=trunksub${suffix_number},segmentation-type=vlan,segmentation-id=$seg_id trunk${suffix_number}
    fi

    openstack server list | grep -q "trunkvm${suffix_number}"
    rc=$?
    if [[ $rc != 0 ]]; then
      echo "Creating server"
      openstack server create --image trunkcirros --flavor trunkflavor --nic port-id=trunkport${suffix_number} trunkvm${suffix_number}
    fi
    suffix_number=$((suffix_number+1))
  done
fi

