#!/bin/sh
##
## Samba: Map `DOMAIN\username` to a local UNIX username
## Copyright (c) 2022 SATOH Fumiyasu @ OSSTech Corp., Japan
##
## License: GNU General Public License version 3
##

## smb.conf:
## ```
## [global]
## username map script = /opt/site/sbin/samba-usernamemap-local
## username map cache time = 60
## ```

set -u

domain_name="${SAMBA_USERNAMEMAP_DOMAIN_NAME:-WORKGROUP}"
min_domain_uid="${SAMBA_USERNAMEMAP_MIN_DOMAIN_UID:-1000}"

smb_username="$1"; shift

case "$smb_username" in
$domain_name\\*)
  unix_username="${smb_username#*\\}"
  ;;
*)
  exit 0
  ;;
esac

unix_uid=$(id -u "$unix_username") || exit $?
if [ "$unix_uid" -lt "$min_domain_uid" ]; then
  exit 0
fi

echo "$unix_username"
exit 0
