websites_up()
{
	local timeout_seconds=2
	if [ $# -eq 0 ]; then
		echo "Provide at least one URL to websites_up"
		return 1
	fi

	code=0
	set +e
	while [ $# -gt 0 ]; do
		url="$1"
		shift
		for i in {1..5}; do
			http_status=`curl -m $timeout_seconds -Is -o /dev/null -w '%{http_code}' "$url"`
			curl_exit=$?
			if [ $curl_exit -eq 28 ]; then
				# timeout, assume there's a weird network issue and try again
				code=1
				continue
			elif [ $curl_exit -ne 0 ]; then
				echo "$url [curl err $curl_exit]"
				code=1
			elif ! echo "$http_status" | grep -q "^[1-4][0-9][0-9]$"; then
				echo "$url [$http_status]"
				code=1
			fi
			break
		done
	done
	set -e

	return $code
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

age_mins()
{
	if [ $# -ne 1 ]; then
		echo "Provide file"
		return 1
	fi

	file="$1"
	
	now=`date +%s`
	last_written=`date -r "$file" +%s`

	if [ -z "$last_written" ]; then
		echo "No last_finished time" 1>&2
		return 1
	fi

	expr \( $now - $last_written \) / 60 || true
}

file_younger_than()
{
	if [ $# -ne 2 ]; then
		echo "Provide file and max_age_mins"
		return 1
	fi

	file="$1"
	max_age_mins=$2
	
	file_age_mins=`age_mins "$file"`

	if [ $file_age_mins -gt $max_age_mins ]; then
		echo "Age of '$file' is older than $max_age_mins mins"
		return 1
	fi
}
