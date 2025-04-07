FROM ghcr.io/tdex-network/tdexd:latest

# Set up environment (environment variables will be injected from Render)
ENV DATA_DIR=/var/data

# Add diagnostic script
RUN echo '#!/bin/sh' > /diagnostic.sh && \
    echo 'echo "===== ENVIRONMENT VARIABLES ====="' >> /diagnostic.sh && \
    echo 'env | sort' >> /diagnostic.sh && \
    echo 'echo "===== DIRECTORY STRUCTURE ====="' >> /diagnostic.sh && \
    echo 'find /usr/local/bin -type f | sort' >> /diagnostic.sh && \
    echo 'echo "===== FILE PERMISSIONS ====="' >> /diagnostic.sh && \
    echo 'ls -la /usr/local/bin/' >> /diagnostic.sh && \
    echo 'echo "===== TRYING HELP COMMAND ====="' >> /diagnostic.sh && \
    echo 'tdex-migration --help || echo "tdex-migration command failed"' >> /diagnostic.sh && \
    chmod +x /diagnostic.sh

ENTRYPOINT ["/diagnostic.sh"]
# Original command (commented out for reference)
# ENTRYPOINT ["tdex-migration"]
# CMD tdex-migration --password "$WALLET_PASSWORD" --ocean-datadir /home/tdex/.tdex-daemon/oceand
