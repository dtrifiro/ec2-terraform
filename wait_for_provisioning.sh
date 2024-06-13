#!/bin/bash

tail -f /var/log/cloud-init-output.log &
tail_pid=$!

until [ -f /var/lib/cloud/instance/boot-finished ]; do
	sleep 1
done

kill $tail_pid
echo "*** Boot has finished!"
