#!/bin/sh
set -ue

for dep in curl jq; do
	err=0
	if ! command -v "$dep" > /dev/null; then
		err=1
		echo "Missing dependency: $dep" 1>&2
	fi

	if [ $err -ne 0 ]; then
		exit $err
	fi
done

if [ $# -ne 1 ]; then
	echo "Provide Pushbullet api token" 1>&2
	exit 1
fi

pushbullet_token=$1
cd "`dirname "$0"`"

pushbullet()
{
	title="`echo $1 | tr -d '\n' | jq -aR .`"
	body="`echo "$2" | jq -aRs .`"

	curl \
		--silent \
		--show-error \
		--output /dev/null \
		--header "Access-Token: $pushbullet_token" \
		--header 'Content-Type: application/json' \
		--data-binary "{\"body\":$body,\"title\":$title,\"type\":\"note\"}" \
		--request POST \
		https://api.pushbullet.com/v2/pushes
}

alert()
{
	title=$1
	body="$2"

	set +e
	out="`pushbullet "$title" "$body" 2>&1`"
	code=$?
	set -e

	if [ $code -ne 0 ]; then
		cat <<EOF | tee -a ~/predmon-alert-failures.log 1>&2
$out
$title: $body
EOF
	fi
}

for c in checks.d/*; do
	[ ! -x "$c" ] && continue

	n="`basename "$c"`"
	f="failing/$n"

	set +e
	out="`(cd checks.d && ./"$n" 2>&1)`"
	code=$?
	set -e

	if [ $code -ne 0 ]; then
		if [ ! -f "$f" ]; then
			alert "Failing: $n" "$out"
			touch "$f"
		fi
	elif [ -f "$f" ]; then
		alert "Passing: $n" "$out"
		rm -f "$f"
	fi
done
