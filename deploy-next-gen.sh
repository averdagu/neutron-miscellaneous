#!/bin/bash

sudo dnf install ansible-core vim tmux /usr/bin/virt-resize -y
sudo dnf install python3 git-core make gcc -y
sudo mkdir -p /root/.ssh
sudo touch /root/.ssh/authorized_keys
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys

git clone https://github.com/openstack-k8s-operators/install_yamls ~/install_yamls

echo 'YOUR_KEY' > ~/install_yamls/devsetup/pull-secret.txt


cd ~/install_yamls

echo 'diff --git a/devsetup/scripts/gen-edpm-compute-node.sh b/devsetup/scripts/gen-edpm-compute-node.sh
index 8c341f9..db2571f 100755
--- a/devsetup/scripts/gen-edpm-compute-node.sh
+++ b/devsetup/scripts/gen-edpm-compute-node.sh
@@ -195,7 +195,7 @@ fi
 
 virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_ADDRESS}' name='${EDPM_COMPUTE_NAME}' ip='192.168.124.${IP_ADRESS_SUFFIX}'/>" --config --live
 virsh define "${OUTPUT_BASEDIR}/${EDPM_COMPUTE_NAME}.xml"
-virt-copy-out -c ${VIRSH_DEFAULT_CONNECT_URI} -d ${EDPM_COMPUTE_NAME} /root/.ssh/id_rsa.pub "${OUTPUT_BASEDIR}"
+sudo virt-copy-out -c ${VIRSH_DEFAULT_CONNECT_URI} -d ${EDPM_COMPUTE_NAME} /root/.ssh/id_rsa.pub "${OUTPUT_BASEDIR}"
 mv -f "${OUTPUT_BASEDIR}/id_rsa.pub" "${OUTPUT_BASEDIR}/${EDPM_COMPUTE_NAME}-id_rsa.pub"
-cat "${OUTPUT_BASEDIR}/${EDPM_COMPUTE_NAME}-id_rsa.pub" | sudo tee -a /root/.ssh/authorized_keys
+cat "${OUTPUT_BASEDIR}/${EDPM_COMPUTE_NAME}-id_rsa.pub" | sudo tee -a ~/.ssh/authorized_keys
 virsh start ${EDPM_COMPUTE_NAME}
' > /tmp/git-apply-edpm.patch

git apply /tmp/git-apply-edpm.patch

for f in `grep -Ir '192.168.122' --exclude=\.* 2>/dev/null | cut -d':' -f1`; do sed -i 's/192.168.122/192.168.124/g' $f; done

cd ~/install_yamls/devsetup
make download_tools

CPUS=6 MEMORY=25600 DISK=120 make crc
if [[ $? != 0 ]]; then
  echo "Failed on make crc"
  exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

make crc_attach_default_interface
if [[ $? != 0 ]]; then
  echo "Failed on make crc_attached_default_interface"
  exit 1
fi

sleep 5

cd ..
make nmstate
if [[ $? != 0 ]]; then
  echo "Failed on nmstate"
  exit 1
fi

sleep 5

make nncp
if [[ $? != 0 ]]; then
  echo "Failed on nncp"
  exit 1
fi

sleep 5

make netattach
if [[ $? != 0 ]]; then
  echo "Failed on netattach"
  exit 1
fi

sleep 5

make metallb
if [[ $? != 0 ]]; then
  echo "Failed on metallb"
  exit 1
fi

sleep 5

make metallb_config
if [[ $? != 0 ]]; then
  echo "Failed on metallb_config"
  exit 1
fi

sleep 5

make crc_storage
if [[ $? != 0 ]]; then
  echo "Failed on crc_storage"
  exit 1
fi

make input
if [[ $? != 0 ]]; then
  echo "Failed on input"
  exit 1
fi

sleep 5

make openstack
if [[ $? != 0 ]]; then
  echo "Failed on make openstack"
  exit 1
fi

sleep 10

export OPENSTACK_CTLPLANE=config/samples/core_v1beta1_openstackcontrolplane_network_isolation.yaml
make openstack_deploy
if [[ $? != 0 ]]; then
  echo "Failed on openstack_deploy"
  exit 1
fi

sleep 5

cd devsetup
make edpm_compute
if [[ $? != 0 ]]; then
  echo "Failed on edpm_compute"
  exit 1
fi

sleep 5

make edpm_compute_repos
if [[ $? != 0 ]]; then
  echo "Failed on edpm_compute_repos"
  exit 1
fi

sleep 5
make edpm_play

if [[ $? != 0 ]]; then
  echo "Failed on edpm_play"
  exit 1
fi
