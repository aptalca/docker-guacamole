#!/bin/sh

BUILD_DIR="$1"
DESTINATION="$2"

cd "$BUILD_DIR"

mkdir -p "$DESTINATION/duo"
tar -xzf extensions/guacamole-auth-duo/target/*.tar.gz \
    -C "$DESTINATION/duo"                              \
    --wildcards                                        \
    --no-anchored                                      \
    --xform="s#.*/##"                                  \
    "*.jar"

mkdir -p "$DESTINATION/cas"
tar -xzf extensions/guacamole-auth-cas/target/*.tar.gz \
    -C "$DESTINATION/cas"                              \
    --wildcards                                        \
    --no-anchored                                      \
    --xform="s#.*/##"                                  \
    "*.jar"

mkdir -p "$DESTINATION/openid"
tar -xzf extensions/guacamole-auth-openid/target/*.tar.gz \
    -C "$DESTINATION/openid"                              \
    --wildcards                                           \
    --no-anchored                                         \
    --xform="s#.*/##"                                     \
    "*.jar"

mkdir -p "$DESTINATION/quickconnect"
tar -xzf extensions/guacamole-auth-quickconnect/target/*.tar.gz \
    -C "$DESTINATION/quickconnect"                              \
    --wildcards                                                 \
    --no-anchored                                               \
    --xform="s#.*/##"                                           \
    "*.jar"

mkdir -p "$DESTINATION/totp"
tar -xzf extensions/guacamole-auth-totp/target/*.tar.gz \
    -C "$DESTINATION/totp"                              \
    --wildcards                                         \
    --no-anchored                                       \
    --xform="s#.*/##"                                   \
    "*.jar"