website_up()
{
	local timeout_seconds=1
	local timeout_retries=5

	if [ $# -ne 1 ]; then
		echo "Provide a URL to website_up"
		return 1
	fi
	url="$1"

	for i in `seq 1 $timeout_retries`; do
		http_out=`set +e; curl -m $timeout_seconds -I -w '%{http_code}\n' "$url" 2>&1; echo $?`
		status=`echo "$http_out" | tail -n2`
		http_status=`echo "$status" | head -n1`
		curl_exit=`echo "$status" | tail -n1`

		echo "$url [curl=$curl_exit, http=$http_status]"

		if [ $curl_exit -eq 28 ]; then
			echo "$url [transient timeout $i, retrying]"
		elif [ $curl_exit -ne 0 ]; then
			echo "$url [curl err $curl_exit]"
			return 1
		elif [ $http_status -lt 100 ] || [ $http_status -ge 500 ]; then
			echo "$url [$http_status]"
			return 1
		else
			return 0
		fi
	done

	echo "$url [fatal timeout]"
	return 1
}

websites_up()
{
	if [ $# -eq 0 ]; then
		echo "Provide at least one URL to websites_up" 1>&2
		return 1
	fi

	code=0
	while [ $# -gt 0 ]; do
		url="$1"
		shift

		website_up "$url"
	done
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
