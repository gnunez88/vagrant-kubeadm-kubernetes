#!/usr/bin/env bash

# Accept self-signed certificate

## Save self-signed certificate from registry for Docker to trust it
sudo mkdir -p /etc/docker/certs.d/${DNS_REGISTRY}:5000
sudo curl http://${DNS_REGISTRY}/cert.pem -o /etc/docker/certs.d/${DNS_REGISTRY}:5000/ca.crt
