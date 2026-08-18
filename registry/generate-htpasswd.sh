#!/bin/bash
# Usage: ./generate-htpasswd.sh <username> <password>

set -e

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <username> <password>"
  exit 1
fi

mkdir -p auth
docker run --rm --entrypoint htpasswd httpd:2 -Bbn "$1" "$2" > auth/htpasswd
chmod 600 auth/htpasswd
