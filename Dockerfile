FROM node:16-slim

# Install necessary tools
RUN apt-get update && apt-get install -y git wget python3 curl --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Download oceand and tdexd binaries and verify they exist
RUN wget -O /usr/local/bin/oceand https://github.com/vulpemventures/ocean/releases/download/v0.2.8/ocean-v0.2.8-linux-amd64 && \
    wget -O /usr/local/bin/tdexd https://github.com/tdex-network/tdex-daemon/releases/download/v2.1.0/tdexd-linux-amd64 && \
    chmod +x /usr/local/bin/oceand /usr/local/bin/tdexd && \
    ls -l /usr/local/bin/tdexd && \
    ls -l /usr/local/bin/oceand

# Create data directory
RUN mkdir -p /app/data

# Set environment variables for tdexd
ENV TDEX_WALLET_ADDR=0.0.0.0:18000
ENV TDEX_LOG_LEVEL=5
ENV TDEX_NO_MACAROONS=true
ENV TDEX_NO_OPERATOR_TLS=true
ENV TDEX_CONNECT_PROTO=http
ENV WALLET_PASSWORD=defaultpassword

# Create a static html file to show status
RUN echo '<html><head><title>TDEX Status</title></head><body><h1>TDEX Services Running</h1><p>Services are running in the background.</p></body></html>' > /app/index.html

# Set up nginx configuration for reverse proxy
RUN echo 'server {\n\
    listen 80;\n\
    server_name localhost;\n\
\n\
    location / {\n\
        proxy_pass http://127.0.0.1:9000;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

# Create startup script
RUN echo '#!/bin/sh\n\
echo "Starting Ocean daemon..."\n\
ls -l /usr/local/bin/tdexd\n\
echo "TDEX binary location:"\n\
which tdexd || echo "tdexd not in PATH"\n\
echo "Starting Ocean daemon..."\n\
/usr/local/bin/oceand --network=regtest --datadir=/app/data --no-tls --no-profiler --db-type=badger --auto-init --auto-unlock > /app/oceand.log 2>&1 &\n\
\n\
# Wait for oceand to start\n\
echo "Waiting for Ocean daemon to start..."\n\
sleep 10\n\
\n\
# Start tdexd in the background with explicit external binding\n\
echo "Starting TDEX daemon..."\n\
/usr/local/bin/tdexd --network=regtest --no-backup --api.addr=0.0.0.0:9000 --external.addr=tdex-test-agau.onrender.com:9000 > /app/tdexd.log 2>&1 &\n\
\n\
# Keep container running and show logs\n\
tail -f /app/tdexd.log /app/oceand.log\n' > /app/start.sh && \
    chmod +x /app/start.sh

# Set up entry point
ENTRYPOINT ["/app/start.sh"]

# Expose necessary ports
EXPOSE 9000 9945 18000
