#!/bin/bash
#
# Setting up Docker

set -euxo pipefail

# Docker

## Add Docker's official GPG key
sudo apt-get update
#sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl
sudo install -o root -g root -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update

## Installing Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

## Enabling the service
sudo systemctl enable --now docker.service
sudo systemctl enable --now containerd.service

