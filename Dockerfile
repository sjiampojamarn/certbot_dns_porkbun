ARG BUILD_FROM=alpine
FROM ${BUILD_FROM} AS build-image

RUN \
  apk add --no-cache python3 python3-dev py3-pip py3-cryptography bash \
  && rm -rf /var/cache/apk/*

WORKDIR /certbot_dns_porkbun

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

ADD requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .
RUN pip install --no-cache-dir .

FROM ${BUILD_FROM}
COPY --from=build-image /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN apk add --no-cache openssl bash python3

COPY ./*.sh ./
RUN chmod +x ./*.sh
