websites_up()
{
	if [ $# -eq 0 ]; then
		echo "Provide at least one URL to websites_up"
		return 1
	fi

	if curl -m 1 -Ifs -o /dev/null https://google.com; then
		code=0
		set +e
		while [ $# -gt 0 ]; do
			url="$1"
			shift
                        http_status=`curl -m 2 -Is -o /dev/null -w '%{http_code}' "$url"`
			curl_exit=$?
			if [ $curl_exit -ne 0 ]; then
				echo "$url [tcp/tls error]"
				code=1
			elif ! echo "$http_status" | grep -q "^[1-4][0-9][0-9]$"; then
				echo "$url [$http_status]"
				code=1
			fi
		done
		set -e

		return $code
	else
		return 0
	fi
}

disk_free_above_percentage()
{
	if [ $# -ne 2 ]; then
		echo "Provide mount_point and min_free_percentage"
		return 1
	fi

	mount_point="$1"
	min_free_percentage="$2"

	percentage_free=`df -h | awk -vmount="$mount_point" '$6 == mount { sub(/%/, "", $5); print 100-$5 }'`
	if [ -z "$percentage_free" ]; then
		echo "Could not find mount point $mount_point"
		return 1
	fi

	if [ $percentage_free -lt $min_free_percentage ]; then
		echo "$mount_point has only $percentage_free% disk space left"
		return 1
	fi
}
