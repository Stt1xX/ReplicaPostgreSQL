FROM pgpool/pgpool:latest

USER root

# Устанавливаем docker CLI
RUN apk update && \
    apk add --no-cache docker-cli

RUN mkdir -p /tmp/oiddir && chown -R postgres:postgres /tmp/oiddir

