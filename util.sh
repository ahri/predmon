websites_up()
{
	if [ $# -eq 0 ]; then
		echo "Provide at least one URL to websites_up"
		return 1
	fi

	if curl -Ifs -o /dev/null https://google.com; then
		code=0
		set +e
		while [ $# -gt 0 ]; do
			url="$1"
			shift
                        http_status=`curl -Is -o /dev/null -w '%{http_code}' "$url"`
                        if [ `echo "$http_status" | wc -l` -ne 1 ] || ! echo "$http_status" | grep -q "^[1-4][0-9][0-9]$"; then
				echo -n "$url"
				if [ ! -z "$http_status" ]; then
					echo -n " [$http_status]"
				fi
				echo
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

	percent_used=`df -h | awk '$6 == "/home" { sub(/%/, "", $5); print $5 }'`
	if [ -z "$percent_used" ]; then
		echo "Could not find mount point $mount_point"
		return 1
	fi

	percentage_free=`expr 100 - $percent_used`
	if [ $percentage_free -lt $min_free_percentage ]; then
		echo "$mount_point has only $percentage_free% disk space left"
		return 1
	fi
}
