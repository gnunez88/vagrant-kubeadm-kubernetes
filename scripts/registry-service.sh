#!/bin/bash
#
# Setup for Registry: Service

set -euxo pipefail

# Registry

## Pulling the image
sudo docker image pull registry

## Creating a Docker-compose file
sudo mkdir -p /opt/registry/data
cat > /opt/registry/docker-compose.yaml << EOF
version: "3.9"

services:
  registry:
    container_name: docker-registry
    image: registry:2
    ports:
      - "127.0.0.1:5001:5000"
    environment:
      REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /var/lib/registry
    volumes:
      - /opt/registry/data:/var/lib/registry
  registry-ui:
    container_name: docker-registry-ui
    image: konradkleine/docker-registry-frontend:v2
    ports:
      - 8080:80
    environment:
      ENV_DOCKER_REGISTRY_HOST: docker-registry
      ENV_DOCKER_REGISTRY_PORT: 5000
    depends_on:
      - registry
EOF

## Creating SystemD unit file (service)
cat > /etc/systemd/system/registry.service << EOF
[Unit]
Description = Docker Registry
Requires = docker.service
After = docker.service

[Service]
Type = oneshot
User = root
Group = docker
WorkingDirectory = /opt/registry
ExecStartPre = /usr/bin/docker compose -f /opt/registry/docker-compose.yaml down
ExecStart    = /usr/bin/docker compose -f /opt/registry/docker-compose.yaml up -d
ExecStop     = /usr/bin/docker compose -f /opt/registry/docker-compose.yaml down
StandardOutput = syslog
RemainAfterExit = yes

[Install]
WantedBy = multi-user.target
RequiredBy = network.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now registry.service

## Running Registry when booting (unnecessary when enabled)
#cat >> /etc/crontab << EOF
#@reboot root    /usr/bin/systemctl start registry.service
#EOF

