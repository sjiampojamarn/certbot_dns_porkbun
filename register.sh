#!/bin/bash

## run forever
while true ; do
  date

  while IFS= read -r line ; do  
    echo $line
    set -x
    certbot certonly \
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
  sleep 12h
  set +x

done
