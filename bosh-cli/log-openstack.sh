#!/bin/bash
#===========================================================================
# Log with Openstack cli tools
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[1;32m'
export STD='\033[0m'
export BOLD='\033[1m'
export REVERSE='\033[7m'

getCredhub() {
  #--- Test if parameter exist with non empty value, else get it from credhub
  if [ "${!1}" = "" ] ; then
    credhubGet=$(credhub g -n $2 -j | jq .value -r)
    if [ $? = 0 ] ; then
      eval $1=$(echo "${credhubGet}")
    else
      printf "\n\n%bERROR : \"$2\" credhub value unknown.%b\n\n" "${RED}" "${STD}"
      flagError=1
    fi
  fi
}

#--- Log to credhub
flagError=0
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "%bEnter CF LDAP user and password :%b\n" "${REVERSE}${YELLOW}" "${STD}"
  credhub api --server=https://credhub.internal.paas:8844 > /dev/null 2>&1
  credhub login
  if [ $? != 0 ] ; then
    printf "\n%bERROR : Bad LDAP authentication.%b\n\n" "${RED}" "${STD}"
    flagError=1
  fi
fi

#--- Log to openstack
if [ "${flagError}" = "0" ] ; then
  #--- Common keystone parameters V2/V3
  getCredhub "OS_AUTH_URL" "/secrets/openstack_auth_url"
  export OS_AUTH_URL
  getCredhub "OS_USERNAME" "/secrets/openstack_username"
  export OS_USERNAME
  getCredhub "OS_PASSWORD" "/secrets/openstack_password"
  export OS_PASSWORD

  unset OS_PROJECT_NAME
  getCredhub "OS_PROJECT_NAME" "/secrets/openstack_project" "test"
  if [ ${flagError} = 0 ] ; then
    #--- Specific keystone V3
    export OS_PROJECT_NAME
    export OS_IDENTITY_API_VERSION="3"
    getCredhub "OS_PROJECT_DOMAIN_NAME" "/secrets/openstack_domain"
    export OS_PROJECT_DOMAIN_NAME
    export OS_USER_DOMAIN_NAME="${OS_PROJECT_DOMAIN_NAME}"
  else
    #--- Specific keystone V2
    flagError=0
    getCredhub "OS_TENANT_NAME" "/secrets/openstack_tenant"
    export OS_TENANT_NAME
    getCredhub "OS_REGION_NAME" "/secrets/openstack_region"
    export OS_REGION_NAME
  fi

  printf "\n"
fi