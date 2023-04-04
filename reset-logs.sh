#!/bin/bash

cd /var/log/containers/neutron
for _f in `find . -name "*.log"`;
do
  cp $_f  $_f.bak
  echo '' > $_f
done

