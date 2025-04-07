FROM golang:1.19-buster as builder

# Install oceand
RUN apt-get update && apt-get install -y wget
RUN wget -O oceand.tar.gz https://github.com/vulpemventures/oceand/releases/download/v0.1.6/oceand_0.1.6_linux_amd64.tar.gz
RUN tar -xzf oceand.tar.gz

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

# Copy oceand from builder
COPY --from=builder /go/oceand /usr/local/bin/

# Use shell form of ENTRYPOINT to avoid chmod issues
ENTRYPOINT echo "===== ENVIRONMENT =====" && \
           env | sort && \
           echo "===== CHECKING OCEAND =====" && \
           ls -la /usr/local/bin/oceand && \
           echo "===== STARTING OCEAND =====" && \
           oceand --network=regtest --datadir=/var/data --no-tls --no-profiler --db-type=badger & \
           echo "Waiting for Ocean daemon to start..." && \
           sleep 10 && \
           echo "Starting TDEX daemon..." && \
           tdexd --no-backup --network=regtest
