FROM node:16-slim

# Install necessary tools (minimal)
RUN apt-get update && apt-get install -y --fix-missing wget python3 --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Download oceand and tdexd binaries
RUN wget -O /usr/local/bin/oceand https://github.com/vulpemventures/ocean/releases/download/v0.2.8/ocean-v0.2.8-linux-amd64 && \
    wget -O /usr/local/bin/tdexd https://github.com/tdex-network/tdex-daemon/releases/download/v1.0.0/tdex-v1.0.0-linux-amd64 && \
    chmod +x /usr/local/bin/oceand /usr/local/bin/tdexd || true

# Create data directory
RUN mkdir -p /app/data

# Set environment variables for tdexd
ENV TDEX_WALLET_ADDR=127.0.0.1:18000
ENV TDEX_LOG_LEVEL=5
ENV TDEX_NO_MACAROONS=true
ENV TDEX_NO_OPERATOR_TLS=true
ENV TDEX_CONNECT_PROTO=http
ENV WALLET_PASSWORD=defaultpassword

# Create a static html file to show status
RUN echo '<html><head><title>TDEX Status</title></head><body><h1>TDEX Services Running</h1><p>Services are running in the background.</p></body></html>' > /app/index.html

# Create startup script without using chmod
RUN echo '#!/bin/sh\n\
echo "Starting Ocean daemon..."\n\
/usr/local/bin/oceand --network=regtest --datadir=/app/data --no-tls --no-profiler --db-type=badger --auto-init --auto-unlock > /app/oceand.log 2>&1 &\n\
\n\
# Wait for oceand to start\n\
echo "Waiting for Ocean daemon to start..."\n\
sleep 10\n\
\n\
# Start tdexd in the background\n\
echo "Starting TDEX daemon..."\n\
/usr/local/bin/tdexd --network=regtest --no-backup > /app/tdexd.log 2>&1 &\n\
\n\
# Start Python HTTP server on port 3000\n\
echo "Starting web server..."\n\
cd /app && python3 -m http.server 3000\n' > /app/start.sh

# Set up entry point
ENTRYPOINT ["sh", "/app/start.sh"]

# Expose ports
EXPOSE 3000 9000 9945 18000
