#!/bin/sh
set -ue

if [ $# -ne 1 ]; then
	echo "Provide a PushBullet API token" 1>&2
	exit 1
fi

pushbullet_api_token="$1"

dirname="`dirname "$0"`"
dirname="`readlink -f "$dirname"`"
run="$dirname/run.sh"

cat <<CRON | crontab
`crontab -l`
PUSHBULLET_API_TOKEN="$pushbullet_api_token"
* * * * * "$run" "\$PUSHBULLET_API_TOKEN"
CRON

cat <<INSTRUCTIONS
The service will now run every minute, executing scripts in $dirname/checks.d

If a script fails (with a non-zero exit code) then you'll be informed via
PushBullet. If your script outputs then that content will be sent along.

You'll be updated again when it starts passing.
INSTRUCTIONS
