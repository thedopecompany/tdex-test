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

# Create a startup script
COPY <<EOF /startup.sh
#!/bin/sh
echo "===== ENVIRONMENT ====="
env | sort
echo "===== DIRECTORY STRUCTURE ====="
find /usr/local/bin -type f | sort
echo "===== CHECKING IF OCEAND EXISTS ====="
which oceand || echo "oceand not found in PATH"
ls -la /usr/local/bin/oceand || echo "oceand not found in /usr/local/bin"

echo "===== STARTING SERVICES ====="
if [ -x "$(command -v oceand)" ]; then
  echo "Starting Ocean daemon..."
  oceand --network=regtest --datadir=/var/data &
  OCEAND_PID=$!
  
  # Wait for oceand to start
  echo "Waiting for Ocean daemon to start..."
  sleep 5
else
  echo "WARNING: oceand binary not found, trying to proceed without it"
fi

# Start tdexd
echo "Starting TDEX daemon..."
exec tdexd --no-backup --network=regtest
EOF

RUN chmod +x /startup.sh

# Use our startup script as the entrypoint
ENTRYPOINT ["/startup.sh"]
