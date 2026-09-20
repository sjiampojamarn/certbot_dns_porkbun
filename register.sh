#!/bin/bash

FORCE=0
ONCE=0

usage() {
  echo "Usage: $0 [--force] [--once]"
  echo "  --force   Force renewal of certificates (certbot --force-renewal)"
  echo "  --once    Run once and exit instead of looping every 12h"
  exit 0
}

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --once)  ONCE=1 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $arg"; usage ;;
  esac
done

## init files 
touch /conf/porkbun.ini
touch /conf/email.ini
touch /conf/register.list

chmod 700 /conf/porkbun.ini

## run forever
while true ; do
  date
  certbot certificates
  
  for d in $(cat /conf/register.list | sed "s/,/ /g") ; do 
    echo $d ;
    echo "Q" | openssl s_client -servername $d -connect ${d}:443 2>/dev/null | openssl x509 -noout -dates ;
  done

  RENEW_ARGS=""
  if [ "$FORCE" = "1" ]; then
    RENEW_ARGS="--force-renewal"
  fi

  while IFS= read -r line ; do  
    echo $line
    set -x
    certbot certonly $RENEW_ARGS \
      --non-interactive \
      --agree-tos \
      --email $(cat /conf/email.ini) \
      --preferred-challenges dns \
      --authenticator dns-porkbun \
      --dns-porkbun-credentials /conf/porkbun.ini \
      --dns-porkbun-propagation-seconds 630 \
      --expand \
      -d "$line" 
    set +x
  done < "/conf/register.list"
  
  ## Post command to prepare pem for HAProxy.
  ./combineFullPrivKeys.sh

  ## Attempt to renew/create every 12h.
  set -x
  if [ "$ONCE" = "1" ]; then
    exit 0
  fi
  sleep 12h
  set +x

done
