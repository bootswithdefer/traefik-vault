#!/bin/dumb-init /bin/sh
set -e

# Note above that we run dumb-init as PID 1 in order to reap zombie processes
# as well as forward signals to all processes in its session. Normally, sh
# wouldn't do either of these functions so we'd leak zombies as well as do
# unclean termination of all our sub-processes.

export CT_CONFIG_DIR="${CT_CONFIG_DIR:-/consul-template/config}"

# You can also set the CT_LOCAL_CONFIG environment variable to pass some
# Consul Template configuration JSON without having to bind any volumes.
if [ -n "$CT_LOCAL_CONFIG" ]; then
  echo "$CT_LOCAL_CONFIG" > "$CT_CONFIG_DIR/local-config.hcl"
fi

if [ -n "$(find "$CT_CONFIG_DIR" -mindepth 1 -maxdepth 1 -type f 2>/dev/null)" ]; then
  /bin/consul-template -consul-addr="$CONSUL_HOST" -consul-ssl -vault-addr="$VAULT_ADDR" -vault-ssl -vault-renew-token="false" -config="$CT_CONFIG_DIR" -once
else
  echo "the directory [$CT_CONFIG_DIR] is empty or non-existent; skipping consul-template configuration"
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- traefik "$@"
fi

# if our command is a valid Traefik subcommand, let's invoke it through Traefik instead
# (this allows for "docker run traefik version", etc)
if traefik "$1" --help 2>&1 >/dev/null | grep "help requested" > /dev/null 2>&1; then
    set -- traefik "$@"
fi

exec "$@"
