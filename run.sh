#!/bin/sh
set -ue

if [ $# -ne 1 ]; then
	echo "Provide Pushbullet api token" 1>&2
	exit 1
fi

pushbullet_token=$1
cd "`dirname "$0"`"

alert()
{
	title="`echo $1 | jq -aR .`"
	body="`echo "$2" | jq -aR .`"

	curl \
		--silent \
		-o /dev/null \
		--header "Access-Token: $pushbullet_token" \
		--header 'Content-Type: application/json' \
		--data-binary "{\"body\":$body,\"title\":$title,\"type\":\"note\"}" \
		--request POST \
		https://api.pushbullet.com/v2/pushes
}

for c in checks.d/*; do
	n="`basename "$c"`"
	f="failing/$n"

	set +e
	out="`sh "$c" 2>&1`"
	code=$?
	set -e

	if [ $code -ne 0 ]; then
		if [ ! -f "$f" ]; then
			alert "Down: $n" "$out"
			touch "$f"
		fi
	elif [ -f "$f" ]; then
		alert "Up: $n" "$out"
		rm -f "$f"
	fi
done
