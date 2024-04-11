#!/bin/bash
#
# Setup for Registry: Images

set -euxo pipefail

config_path="/vagrant/configs"

# Docker Images

## Pulling Docker Images from Docker Hub
DCKUSER="madhuakula"
DCKIMG=(
  # Kubernetes GOAT
  $DCKUSER/hacker-container
  $DCKUSER/k8s-goat-batch-check
  $DCKUSER/k8s-goat-build-code
  $DCKUSER/k8s-goat-cache-store
  $DCKUSER/k8s-goat-health-check        # requires Docker
  $DCKUSER/k8s-goat-hidden-in-layers
  $DCKUSER/k8s-goat-home
  $DCKUSER/k8s-goat-hunger-check
  $DCKUSER/k8s-goat-info-app
  $DCKUSER/k8s-goat-internal-api
  $DCKUSER/k8s-goat-poor-registry
  $DCKUSER/k8s-goat-system-monitor
  aquasec/kube-bench                    # security tool
  busybox
  # OWASP - WrongSecrets
  jeroenwillemsen/wrongsecrets:1.8.5test5-no-vault
  jeroenwillemsen/wrongsecrets:1.8.5test5-k8s-vault
  # BishopFox - badPods
  raesene/ncat
  ubuntu
  # Extra images
  alpine
  django
  drupal
  httpd
  jenkins/jenkins
  memcached
  mongo
  mongo-express
  mariadb
  mysql
  nginx
  node
  owncloud
  phpmyadmin
  postgres
  python
  rabbitmq
  redis
  tomcat
  wordpress
)

#### Pulling from Docker hub, pushing to private registry
for img in ${DCKIMG[@]}; do
  sudo docker image pull $img
  sudo docker image tag $img $HOSTNAME:5000/$img
  sudo docker image push $HOSTNAME:5000/$img
done

#### Removing local images not belonging to the registry
for img in ${DCKIMG[@]}; do
  sudo docker image rm $img $HOSTNAME:5000/$img
done

