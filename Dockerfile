FROM ghcr.io/tdex-network/tdexd:latest

# Set up environment (environment variables will be injected from Render)
ENV DATA_DIR=/var/data
ENTRYPOINT ["tdex-migration"]
CMD tdex-migration --password "$WALLET_PASSWORD" --ocean-datadir /home/tdex/.tdex-daemon/oceand
