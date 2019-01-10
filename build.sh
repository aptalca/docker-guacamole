#!/bin/bash

REPOSITORY="$1"

VERSION="$2"

docker build --rm --target nomariadb -t "$REPOSITORY"/guacamole:"$VERSION"-nomariadb .

docker build --rm -t "$REPOSITORY"/guacamole:"$VERSION" .