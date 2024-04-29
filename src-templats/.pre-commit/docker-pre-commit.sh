#!/bin/bash
docker run \
    --user $(id -u):$(id -g) \
    --rm \
    -v "$(pwd):/opt/simple-backend" \
    --workdir "/opt/simple-backend" \
    -t registry.inspector-cloud.com/ic/simple-backend_docker/pre-commit:python3.12 \
    "$@"
