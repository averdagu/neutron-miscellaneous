#!/bin/bash

cd ~/tempest-dir
function="tempest.api.compute.admin.test_live_migration.LiveMigrationTest.test_live_migration_with_trunk"
if [[ -n $1 ]]; then
  function=$1
fi
success=0
failure=0

for i in `seq 1 20`; do
  stestr run -- $function | grep -q "Passed: 1"
  ret_val=$?
  if [[ $ret_val == 0 ]]; then
    echo "Test $i: GOOD"
    success=$((success+1))
  else
    echo "Test $i: BAD"
    failure=$((failure+1))
  fi
done

