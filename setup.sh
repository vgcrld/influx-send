#!/usr/bin/env sh


[ -z "${1}" ] && echo "must enter token" && exit 1

curl -o gpe-oracle-backup-send.sh 'https://raw.githubusercontent.com/vgcrld/gpe-tagset-oracle-backup/master/gpe-oracle-backup-send.sh'
chmod +x gpe-oracle-backup-send.sh
echo "${1}" > .gpe-tagset-token
chmod 640 .gpe-tagset-token