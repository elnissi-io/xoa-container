# Use a multi-stage build to keep the final image as clean and minimal as possible
# Builder container for Xen-Orchestra
FROM node:18-bullseye as build

# Install build and Python dependencies
RUN apt-get update && \
    apt-get install -y build-essential libpng-dev ca-certificates git fuse && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Fetch Xen-Orchestra sources from git stable branch
RUN git clone -b master https://github.com/vatesfr/xen-orchestra /etc/xen-orchestra

# Run build tasks against sources
RUN cd /etc/xen-orchestra && \
    yarn config set network-timeout 200000 && \
    yarn && \
    yarn build

# Install plugins
RUN find /etc/xen-orchestra/packages/ -maxdepth 1 -mindepth 1 -not -name "xo-server" -not -name "xo-web" -not -name "xo-server-cloud" -not -name "xo-server-test" -not -name "xo-server-test-plugin" -exec ln -s {} /etc/xen-orchestra/packages/xo-server/node_modules \;

# Runner container for Xen-Orchestra
FROM node:18-bullseye-slim

# Install runtime dependencies and Poetry
RUN apt-get update && \
    apt-get install -y jq redis-server git libvhdi-utils python3 python3-pip lvm2 nfs-common netbase cifs-utils ca-certificates monit procps curl ntfs-3g && \
    pip3 install poetry && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install xo-cli and forever globally
RUN npm install -g xo-cli forever

# Copy built Xen Orchestra from builder
COPY --from=build /etc/xen-orchestra /etc/xen-orchestra

# Setup logging to Docker logs
RUN ln -sf /proc/1/fd/1 /var/log/redis/redis-server.log && \
    ln -sf /proc/1/fd/1 /var/log/xo-server.log && \
    ln -sf /proc/1/fd/1 /var/log/monit.log

# Add healthcheck script
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh
HEALTHCHECK --start-period=1m --interval=30s --timeout=5s --retries=2 CMD /healthcheck.sh

# Add configuration template and monit services
COPY conf/xo-server.toml.j2 /xo-server.toml.j2
COPY conf/monit-services /etc/monit/conf.d/services
COPY conf.yaml /conf.yaml

# Clone xoadmin with specific tag v1.1.0
RUN git clone --branch v1.2.4 --depth 1 https://github.com/elnissi-io/xoadmin /xoadmin
RUN cd /xoadmin && pip install . --ignore-requires-python

COPY run.sh /run.sh
COPY scripts /scripts
RUN chmod +x /run.sh

CMD ["sh", "-c", "cd /etc/xen-orchestra/packages/xo-server && /run.sh"]
EXPOSE 80
