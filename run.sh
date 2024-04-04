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

function deleteUserByEmail() {
	# The email address of the user to delete
	local USER_EMAIL="$1"

	# Check if an email address is provided
	if [ -z "$USER_EMAIL" ]; then
		echo "Usage: deleteUserByEmail <user-email>"
		return 1
	fi

	# Get the user ID for the given email address using jq for JSON parsing
	local USER_ID=$(xoadmin user list --format json | jq -r --arg email "$USER_EMAIL" '.[] | select(.email==$email) | .id')

	# Check if the user ID was found
	if [ -z "$USER_ID" ]; then
		echo "Error: User not found."
		return 2
	fi

	# Delete the user by ID
	xoadmin user delete "$USER_ID"

	echo "User $USER_EMAIL deleted successfully."
}

check_xo_ready
mkdir $HOME/.xoadmin

alias xoadmin="/usr/bin/python3 -m xoadmin"

xoadmin config generate -o $HOME/.xoadmin/config
xoadmin apply -f /conf.yaml
xoadmin user create $XO_ADMIN_USER $XO_ADMIN_PASSWORD --permission admin
deleteUserByEmail admin@admin.net
xoadmin config set username --from-env --env-var XO_ADMIN_USER
xoadmin config set password --from-env --env-var XO_ADMIN_PASSWORD

echo "OK."

while true; do
	sleep 1d
done &
wait $!
