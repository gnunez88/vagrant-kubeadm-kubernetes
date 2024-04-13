#!/bin/bash
#
# Setting up a Reverse Proxy

set -euxo pipefail

# Nginx

## Installation
sudo apt-get update
sudo apt-get install -y nginx openssl

## Certificate
sudo mkdir -p /etc/nginx/certs
sudo cat > /etc/nginx/certs/registry-san.conf << EOF
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
countryName = ${COUNTRY}
stateOrProvinceName = ${STATE}
localityName = N/A
organizationName = ${ORG}
commonName = ${CN}

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = ${IP_REGISTRY}
DNS.1 = ${DNS_REGISTRY}
EOF

sudo openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 -keyout /etc/ssl/private/registry.key \
  -out /etc/ssl/certs/registry.crt \
  -config /etc/nginx/certs/registry-san.conf
  #-subj "/C=${COUNTRY}/ST=${STATE}/O=${ORG}/OU=${OU}/CN=${CN}" \

### Make the certificate available to the nodes
sudo cp /etc/ssl/certs/registry.crt /usr/share/nginx/html/cert.pem

## Configuration
NGINX=/etc/nginx

### Web Server
cat > $NGINX/sites-available/default << EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  root /usr/share/nginx/html;

  server_name _;

  location / {
    try_files \$uri \$uri/ =404;
  }
}
EOF

### Reverse Proxy
cat > $NGINX/sites-available/registry << EOF
upstream backend_registry {
  server 127.0.0.1:5001;
}

server {
  listen 5000 ssl;
  listen [::]:5000 ssl;

  ssl_certificate /etc/ssl/certs/registry.crt;
  ssl_certificate_key /etc/ssl/private/registry.key;

  server_name registry;

  # To upload Docker images and avoid error 413 "Request Entity Too Large"
  client_max_body_size 0;

  location / {
    proxy_pass http://backend_registry;
    include proxy_params;
  }
}
EOF

sudo ln -sf $NGINX/sites-available/registry $NGINX/sites-enabled/registry

## Enabling the service
sudo systemctl enable --now nginx.service
sudo systemctl restart nginx.service

