#!/bin/bash 

for CERTIFICATE in `find /etc/letsencrypt/live/* -type d`; do
  CERTIFICATE=`basename $CERTIFICATE`
  echo $CERTIFICATE
  set -x
  cat /etc/letsencrypt/live/$CERTIFICATE/fullchain.pem /etc/letsencrypt/live/$CERTIFICATE/privkey.pem > /etc/letsencrypt/live/$CERTIFICATE/fullchain.privkey.pem
  chmod 700 /etc/letsencrypt/live/$CERTIFICATE/fullchain.privkey.pem
  set +x
done
