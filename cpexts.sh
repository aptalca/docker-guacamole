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

mkdir -p "$DESTINATION/header"
tar -xzf extensions/guacamole-auth-header/target/*.tar.gz \
    -C "$DESTINATION/header"                              \
    --wildcards                                           \
    --no-anchored                                         \
    --xform="s#.*/##"                                     \
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

mkdir -p "$DESTINATION/saml"
tar -xzf extensions/guacamole-auth-saml/target/*.tar.gz \
    -C "$DESTINATION/saml"                              \
    --wildcards                                         \
    --no-anchored                                       \
    --xform="s#.*/##"                                   \
    "*.jar"

mkdir -p "$DESTINATION/totp"
tar -xzf extensions/guacamole-auth-totp/target/*.tar.gz \
    -C "$DESTINATION/totp"                              \
    --wildcards                                         \
    --no-anchored                                       \
    --xform="s#.*/##"                                   \
    "*.jar"