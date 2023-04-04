#!/bin/bash

if [[ -n $1 ]]; then
  SUFFIX=$1
else
  echo -e "Usage: copy-logs.sh SUFFIX "
  echo -e "\t- SUFFIX: will create a /tmp/SUFFIX folder and copy"
  echo -e "\tall files (server, ovnnb and ovnsb) with name name.suffix"
  echo -e "\tand finally will run small-logs on server.log"
fi

if [[ -d /tmp/$SUFFIX ]]; then
  echo "Directory exists, please remove it."
  exit
fi

if [[ ! -f ~/small-logs.py ]]; then
  #   import sys
  #   name = sys.argv[1]
  #
  #   with open(name, "r+") as fin, open(name+".min", "w") as fout:
  #       for l in fin.readlines():
  #           if '[' in l and ']' in l:
  #               l = l[:l.find('[')+1] + l[l.find(']'):]
  #           fout.write(l)
  echo "Small-logs doesn't exist, create it."
  exit
fi

mkdir -p /tmp/$SUFFIX
cd /tmp/$SUFFIX
cp ~/small-logs.py .

# Copy sever.log
scp controller-0.ctlplane:/tmp/server.log server.log.$SUFFIX
python3 small-logs.py server.log.$SUFFIX
# Copy NB
scp controller-0.ctlplane:/tmp/ovnnb_db.db ovnnb_db.db.$SUFFIX
# Copy SB
scp controller-0.ctlplane:/tmp/ovnsb_db.db ovnsb_db.db.$SUFFIX

