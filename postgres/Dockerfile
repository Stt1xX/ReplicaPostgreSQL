FROM postgres:15

# Устанавливаем инструменты
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    cron \
    postgresql-client \
    docker-cli \
    && rm -rf /var/lib/apt/lists/*

# Копируем кастомный entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint-custom.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-custom.sh"]
CMD ["postgres"]
