#!/bin/bash
#===========================================================================
# Log with Bosh cli V2
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[1;32m'
export STD='\033[0m'
export BOLD='\033[1m'
export REVERSE='\033[7m'

unset BOSH_CLIENT
unset BOSH_CLIENT_SECRET
status=0

if [ ! -s "${BOSH_CA_CERT}" ] ; then
  printf "\n%bERROR : CA cert file \"${BOSH_CA_CERT}\" unknown.%b\n\n" "${RED}" "${STD}"
else
  #--- Identify BOSH director
  flag=0
  while [ ${flag} = 0 ] ; do
    flag=1
    printf "\n%bDirector BOSH :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
    printf "%b1%b : micro\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b2%b : master\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b3%b : ops\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b4%b : coab\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b5%b : kubo\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b6%b : ondemand\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b7%b : expe\n" "${GREEN}${BOLD}" "${STD}"
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    case "${choice}" in
      1) BOSH_TARGET="micro" ;;
      2) BOSH_TARGET="master" ;;
      3) BOSH_TARGET="ops" ;;
      4) BOSH_TARGET="coab" ;;
      5) BOSH_TARGET="kubo" ;;
      6) BOSH_TARGET="ondemand" ;;
      7) BOSH_TARGET="expe" ;;
      *) flag=0 ; clear ;;
    esac
  done

  #--- Check if bosh dns exists
  export BOSH_ENVIRONMENT=$(host bosh-${BOSH_TARGET}.internal.paas | awk '{print $4}')
  if [ "${BOSH_ENVIRONMENT}" = "found:" ] ; then
    printf "\n\n%bERROR : Bosh director \"${BOSH_TARGET}\" unknown (no dns record).%b\n\n" "${RED}" "${STD}"
  else
    #--- Check if bosh director vm is available
    nc -vz -w 1 ${BOSH_ENVIRONMENT} 25250 > /dev/null 2>&1
    if [ $? != 0 ] ; then
      printf "\n\n%bERROR : Bosh director \"${BOSH_TARGET}\" unreachable.%b\n\n" "${RED}" "${STD}"
    else
      status=1
      testToken=$(bosh env > /dev/null 2>&1)
      if [ $? != 0 ] ; then
        #--- Token expired, log out
        bosh log-out > /dev/null 2>&1
      fi

      userConnected=$(bosh env | grep "not logged in")
      if [ "${userConnected}" != "" ] ; then
        #--- Log into the director and list active deployments
        bosh alias-env ${BOSH_TARGET} > /dev/null 2>&1
        printf "\n%bCF LDAP user and password :%b\n" "${REVERSE}${YELLOW}" "${STD}"
        bosh log-in
        if [ $? != 0 ] ; then
          printf "\n\n%bERROR : Log to bosh director \"${BOSH_TARGET}\" failed.%b\n\n" "${RED}" "${STD}"
          status=0
        fi
      fi
    fi
  fi
fi

#--- Select specific deployment
if [ ${status} = 1 ] ; then
  deployments=$(bosh deployments --column=Name | grep -vE "^Name$|^Succeeded$|^[0-9]* deployments$")
  printf "\n%bSelect a specific deployment in the list, or suffix your bosh commands with -d <deployment_name>:%b\n%s" "${REVERSE}${YELLOW}" "${STD}" "${deployments}"
  printf "\n\n%bYour choice (<Enter> to select none) :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
  if [ "${choice}" = "" ] ; then
    unset BOSH_DEPLOYMENT
  else
    flag=$(echo "${deployments}" | grep "${choice}")
    if [ "${flag}" = "" ] ; then
      unset BOSH_DEPLOYMENT
    else
      export BOSH_DEPLOYMENT="${choice}"
      bosh instances
    fi
  fi
fi
printf "\n"