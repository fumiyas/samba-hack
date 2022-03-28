#!/bin/bash
##
## Active Directory: Search schema entries
## Copyright (c) 2022 SATOH Fumiyasu @ OSSTech Corp., Japan
##
## License: GNU General Public License version 3
##

set -u
export LDAPTLS_REQCERT=never

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 AD.EXAMPLE.JP [OBJECT_CLASS_NAME ...]"
    exit 1
fi

realm="$1"; shift
suffix="dc=${realm//./,dc=}"

ldap_uri="ldaps://$realm"
ldap_bind_dn="administrator@$realm"
ldap_search_base="cn=schema,cn=configuration,$suffix"

ldap_search() {
  ldapsearch \
    -H "$ldap_uri" \
    -x \
    -D "$ldap_bind_dn" \
    -W \
    -b "$ldap_search_base" \
    -s sub \
    -E "!pr=1000/noprompt" \
    -o ldif-wrap=no \
    -LLL \
    "$@" \
  ;
}

## https://docs.microsoft.com/en-us/windows/win32/adschema/c-classschema
oc_attrs=(
  objectClass
  objectClassCategory
  lDAPDisplayName
  description
  governsID
  mustContain
  mayContain
  #showInAdvancedViewOnly
)

## https://docs.microsoft.com/en-us/windows/win32/adschema/c-attributeschema
attr_attrs=(
  objectClass
  lDAPDisplayName
  description
  attributeID
  attributeSyntax
  searchFlags
  isSingleValued
  rangeLower
  rangeUpper
  extendedCharsAllowed
  #showInAdvancedViewOnly
)

if [[ $# -eq 0 ]]; then
  oc_names=('*')
  attr_names=('*')
else
  oc_names=("$@")
  attr_names=($(
    for oc_name in "${oc_names[@]}"; do
      ldap_search \
	"(&(objectClass=classSchema)(cn=$oc_name))" \
	mustContain \
	mayContain \
      |sed -n \
	-e 's/^mustContain: //p' \
	-e 's/^mayContain: //p' \
      || exit $? \
      ;
    done \
    |sort -u \
    ;
  )) \
  || exit $? \
  ;
fi

for attr_name in "${attr_names[@]}"; do
  ldap_search \
    "(&(objectClass=attributeSchema)(cn=$attr_name))" \
    "${attr_attrs[@]}" \
  || exit $? \
  ;
done

for oc_name in "${oc_names[@]}"; do
  ldap_search \
    "(&(objectClass=classSchema)(cn=$oc_name))" \
    "${oc_attrs[@]}" \
  || exit $? \
  ;
done
