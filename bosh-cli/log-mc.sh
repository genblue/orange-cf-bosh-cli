#!/bin/bash
#===========================================================================
# Log with mc (S3) cli
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

#--- Log to S3
if [ "${flagError}" = "0" ] ; then
  getCredhub "S3_SECRET_KEY" "/micro-bosh/minio-private-s3/s3_secretkey"
  if [ ${flagError} = 0 ] ; then
    mc config host add minio http://private-s3.internal.paas:9000 private-s3 ${S3_SECRET_KEY} > /dev/null 2>&1
    if [ $? = 1 ] ; then
      printf "\n%bERROR : Connexion failed.%b\n\n" "${RED}" "${STD}"
    fi
  fi
fi
printf "\n"