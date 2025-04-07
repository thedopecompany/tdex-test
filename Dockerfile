FROM ghcr.io/tdex-network/tdexd:latest

# Set up environment (environment variables will be injected from Render)
ENV DATA_DIR=/var/data
ENTRYPOINT ["tdex-migration"]
CMD tdex-migration --password "yourpasswordhere" --ocean-datadir /home/tdex/.tdex-daemon/oceand
