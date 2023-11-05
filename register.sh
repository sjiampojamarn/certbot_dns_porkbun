#!/bin/bash

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
