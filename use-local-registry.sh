#!/usr/bin/env bash

# Usage: use-local-registry.sh registry:5000 scripts
REGISTRY="${1:-registry:5000}"
ROOTDIR="${2:-.}"

# Search for YAML files and prepend "$REGISTRY" to the images
find "${ROOTDIR}" -type f \
    -regextype egrep -iregex ".*\.ya?ml" -print0 \
    | xargs -0 -I{} \
    sed -ri "s#image: ([^{]+)\$#image: ${REGISTRY}/\1#" {}
