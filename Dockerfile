FROM ghcr.io/tdex-network/tdexd:latest

# Set up environment variables
ENV DATA_DIR=/var/data
ENV WALLET_PASSWORD=defaultpassword
ENV TDEX_WALLET_ADDR=oceand:18000
ENV TDEX_LOG_LEVEL=5
ENV TDEX_FEE_ACCOUNT_BALANCE_THRESHOLD=1000
ENV TDEX_NO_MACAROONS=true
ENV TDEX_NO_OPERATOR_TLS=true
ENV TDEX_CONNECT_PROTO=http

# Simple entrypoint 
ENTRYPOINT ["tdexd"]
CMD ["--no-backup", "--network=regtest"]
