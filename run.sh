#!/bin/bash

function StopProcesses {
	while [ $(/usr/bin/monit status | sed -n '/^Process/{n;p;}' | awk '{print $2}' | grep -c OK) != 0 ]; do
		sleep 1
		/usr/bin/monit stop all
	done
	exit 0
}

set -a
HTTP_PORT=${HTTP_PORT:-"80"}
CERT_PATH=${CERT_PATH:-\'./temp-cert.pem\'}
KEY_PATH=${KEY_PATH:-\'./temp-key.pem\'}
set +a

/usr/bin/python3 -c 'import os; import sys; import jinja2; sys.stdout.write(jinja2.Template(sys.stdin.read()).render(env=os.environ))' </xo-server.toml.j2 >/etc/xen-orchestra/packages/xo-server/.xo-server.toml

# Start services
trap StopProcesses EXIT TERM
/usr/bin/monit && /usr/bin/monit start all

function check_xo_ready {
	local retries=30
	local wait_seconds=10

	echo "Checking Xen Orchestra readiness..."

	for ((i = 0; i < retries; i++)); do
		# Use curl to send a request to Xen Orchestra's HTTP endpoint
		if /usr/bin/curl -s -k -L -I -m 3 http://127.0.0.1:${HTTP_PORT} >/dev/null; then
			echo "Xen Orchestra is ready."
			return 0
		fi

		echo "Waiting for Xen Orchestra to become ready. Attempt $((i + 1)) of $retries."
		sleep $wait_seconds
	done

	echo "Failed to detect Xen Orchestra readiness after $retries attempts."
	exit 1
}

check_xo_ready
/usr/bin/python3 /scripts/xoa_init.py --config /conf.yaml

echo "OK."

while true; do
	sleep 1d
done &
wait $!
