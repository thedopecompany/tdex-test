FROM ghcr.io/tdex-network/tdexd:latest

# Set up environment variables
ENV DATA_DIR=/var/data
ENV WALLET_PASSWORD=defaultpassword

# Simple entrypoint 
ENTRYPOINT ["tdexd"]
CMD ["--no-backup", "--no-macaroons", "--network=regtest"]
