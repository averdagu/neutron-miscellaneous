#!/bin/bash
. `find ~/ -name overcloudrc`

COMPUTE_ARRAY=("compute-0.redhat.local" "compute-1.redhat.local" "compute-2.redhat.local" "compute-3.redhat.local")

NUMBER=1
PUBLIC_NETWORK="public"
vm_name="cvm"

while getopts 'd:Dn:' OPTION; do
  case $OPTION in
    n)
      NUMBER=$OPTARG
      ;;
  esac
done

create_common_things() {
  if [[ ! -f /tmp/cirros.img ]]; then
    curl -k -L http://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img > /tmp/cirros.img
  fi

  openstack image list | grep -q 'cirros'
  rc=$?
  if [[ $rc != 0 ]]; then
    openstack image create cirros --file /tmp/cirros.img --disk-format qcow2 --container-format bare --public
  fi

  openstack flavor list | grep -q 'm1.tiny'
  rc=$?
  if [[ $rc != 0 ]]; then
    openstack flavor create --disk 1 --ram 128 m1.tiny
  fi

  openstack network list | grep -q 'net1'
  rc=$?
  if [[ $rc != 0 ]]; then
    openstack network create net1
  fi

  openstack subnet list | grep -q 'subnet1'
  rc=$?
  if [[ $rc != 0 ]]; then
    openstack subnet create --subnet-range 192.168.100.0/24 --network net1 subnet1
  fi

  openstack router list | grep -q 'router1'
  rc=$?
  if [[ $rc != 0 ]]; then
    openstack router create router1
    openstack router add subnet router1 subnet1
    openstack router set --external-gateway $PUBLIC_NETWORK router1
  fi
  
  openstack security group list | grep -q 'secgroup1'
  rc=$?
  if [[ $rc != 0 ]]; then
    openstack security group create secgroup1
    openstack security group rule create --protocol tcp --dst-port 22 secgroup1
    openstack security group rule create --protocol icmp secgroup1
  fi

}

create_vms() {
  local name=$1
  openstack server create --nic net-id=net1 --flavor m1.tiny --image cirros --security-group secgroup1 $name &> /dev/null
  #openstack floating ip create --port $(openstack port list --server $name -c id -f value) public
}

delete_vms() {
  local name=$1
  openstack server delete $name
}

migrate_vms() {
  local name=$1
  it=$((RANDOM % 4))
  new_host=${COMPUTE_ARRAY[$it]}
  og_host=$(openstack server show $name -f value -c OS-EXT-SRV-ATTR:host)
  if [[ $new_host == $og_host ]]; then
    it=$((it+1))
    it=$((it%4))
    new_host=${COMPUTE_ARRAY[$it]}
  fi
  #echo "Migrating from $og_host to $new_host"
  openstack server migrate --live-migration --block-migration --wait --host $new_host  $name &> /dev/null
}

wait_for_port() {
  local name=$1
  for i in `seq 1 15`; do
    stat=`openstack port list --server $name -f value -c status`
    if [[ $stat == "ACTIVE" ]]; then
      break
    fi
    sleep 1
  done
  for i in `seq 1 15`; do
    stat=`openstack server show $name -f value -c status`
    if [[ $stat == "ACTIVE" ]]; then
      break
    fi
    sleep 1
  done
}

print_port_status() {
  local name=$1
  openstack port list --server $name -f value -c status
}

last_vm=""

#create_common_things

for i in `seq 1 $NUMBER`; do
  create_vms $vm_name$i 
  last_vm=$vm_name$i
done

wait_for_port $last_vm

for i in `seq 1 $NUMBER`; do
  echo "Migrate vm: $vm_name$i"
  print_port_status $vm_name$i
  migrate_vms $vm_name$i
  print_port_status $vm_name$i
done

for i in `seq 1 $NUMBER`; do
  delete_vms $vm_name$i
done

