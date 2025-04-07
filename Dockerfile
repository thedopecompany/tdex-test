FROM ghcr.io/tdex-network/tdexd:latest

# Set up environment variables
ENV DATA_DIR=/var/data
ENV WALLET_PASSWORD=defaultpassword
ENV TDEX_WALLET_ADDR=127.0.0.1:18000
ENV TDEX_LOG_LEVEL=5
ENV TDEX_FEE_ACCOUNT_BALANCE_THRESHOLD=1000
ENV TDEX_NO_MACAROONS=true
ENV TDEX_NO_OPERATOR_TLS=true
ENV TDEX_CONNECT_PROTO=http

# Create a startup script to start both oceand and tdexd
COPY <<EOF /startup.sh
#!/bin/sh
# Start oceand in the background
echo "Starting Ocean daemon..."
oceand --network=regtest --datadir=/var/data &
OCEAND_PID=$!

# Give oceand some time to start up
sleep 5

# Start tdexd
echo "Starting TDEX daemon..."
exec tdexd --no-backup --network=regtest

# If tdexd exits, kill oceand as well
kill $OCEAND_PID
EOF

RUN chmod +x /startup.sh

# Use our startup script as the entrypoint
ENTRYPOINT ["/startup.sh"]
