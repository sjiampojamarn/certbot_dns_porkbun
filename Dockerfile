ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apk add --no-cache python3 py3-pip py3-cryptography bash \
  && rm -rf /var/cache/apk/*

WORKDIR /certbot_dns_porkbun

ADD requirements.txt requirements.txt
RUN pip3 install -r requirements.txt && pip3 cache purge

COPY . .
RUN chmod +x ./*.sh && pip install .

