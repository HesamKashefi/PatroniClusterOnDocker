FROM postgres:17-alpine AS postgres-patroni

ENV PG_VERSION=17

# Install dependencies for Patroni (Python-based) and gosu
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk update \
    && apk add --no-cache build-base linux-headers python3-dev py3-pip py3-virtualenv gosu \
    && python3 -m venv /venv && mkdir /venv/etc

# Set working directory for installation
WORKDIR /venv

# Install Patroni and required extras (e.g., for etcd support)
RUN ./bin/pip install --no-cache-dir psycopg2 patroni[etcd3]

# Copy Patroni configuration file (you'll create this separately)
COPY patroni.yml /venv/etc/patroni.yml

# Set working directory to PostgreSQL home
WORKDIR /var/lib/postgresql

# Copy custom entrypoint script (you'll create this separately)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENV PATRONI_CONFIG_FILE=/venv/etc/patroni.yml

# Make the entrypoint executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Expose PostgreSQL and Patroni REST API ports
EXPOSE 5432 8008