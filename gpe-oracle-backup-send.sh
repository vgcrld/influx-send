#!/usr/bin/env sh

# It is required that you put a .gpe-tagset-token file in the same location as this script.
# This must be a GPE send token with access to the site you wish to write to.
#
# Use a similiar command, where token_string is the token you would like to store.
# Make sure the permissions are correct for the user. Probably oracle, for example:
# echo "eyJzZWMiOiI3NDdlNzZkZmN..yNWZjM2VlOSJ9" > .gpe-tagset-token && chmod 640 .gpe-tagset-token
#
# Access the search facility to search through tags. Add the gpe :site name
# https://my.galileosuite.com/:customer/tagset/search?range_type=last_60&case_sensitive=falseß

# Some Setup
GPE_SEND_HOME="$(dirname $0)"; cd "${GPE_SEND_HOME}"
GPE_SEND_TOKEN=$(head -1 .gpe-tagset-token)
GPE_SEND_URL="xfer1.galileosuite.com"

# Set to 1 if -x and post will execute, otherwise print
GPE_SEND_EXECUTE=0

# Usage message
usage() {
  ! [ -z "$1" ] && echo "$1"
  echo "Usage: ${0} -d database_name -t backup_type -c db_capacity_mib -s exit_code -z transfer_mib [ -x -h ]"
  exit 1
}

# Do the post
doPost() {
      curl -X POST \
      "https://${GPE_SEND_URL}/ingest/influxdb/atsgroup/write" \
      --header 'Accept: */*' \
      --header 'User-Agent: Galileo-Tagset-Post-Oracle-Backup' \
      --header "Authorization: Bearer $GPE_SEND_TOKEN" \
      --header 'Content-Type: text/plain' \
      --data-raw "${GPE_SEND_STRING}" -k
      return $?
}

# Loop through the options.
while getopts "d:t:c:s:z:xh" o; do
    case "${o}" in
        d)
            GPE_SEND_DB=${OPTARG}
            ;;
        t)
            GPE_SEND_TYPE=${OPTARG}
            ;;
        c)
            GPE_SEND_CAPACITY=${OPTARG}
            ;;
        s)
            GPE_SEND_EXITCODE=${OPTARG}
            ;;
        z)
            GPE_SEND_XFER=${OPTARG}
            ;;
        x)
            GPE_SEND_EXECUTE=1
            ;;
        h)
            usage "GPE Oracle Backup Tagset Write Helper"
            ;;
        *)
            usage
            ;;
    esac
done

# Then check the options
[ -z ${GPE_SEND_DB} ]       && usage "error, missing database_name (-d)"
[ -z ${GPE_SEND_TYPE} ]     && usage "error, missing backup_type (-t)"
[ -z ${GPE_SEND_CAPACITY} ] && usage "error, missing db_capacity_mib (-c)"
[ -z ${GPE_SEND_EXITCODE} ] && usage "error, missing exit_code (-s)"
[ -z ${GPE_SEND_XFER} ]     && usage "error, missing transfered_mib (-z)"

# Now that we have all of our options, shift them off and leave
# the input args what is left over. 
shift $((OPTIND-1))

GPE_SEND_STRING="oracle_backup,database_name=${GPE_SEND_DB},backup_type=${GPE_SEND_TYPE},action=backup,hostname=$(hostname -s) db_capacity_mib=$GPE_SEND_CAPACITY,transfered_mib=${GPE_SEND_XFER},exit_code=${GPE_SEND_EXITCODE}"

if [ "${GPE_SEND_EXECUTE}" == "1" ]
then
    if ! doPost ; then
      echo "Failed: $?"
    fi
else
    usage "NOT SENT (add -x): ${GPE_SEND_STRING}"
fi

exit 0