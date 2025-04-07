FROM ghcr.io/tdex-network/tdexd:latest

# Set up environment (environment variables will be injected from Render)
ENV DATA_DIR=/var/data

# Create a simple wrapper script to print debug info and then run the command
USER root
WORKDIR /home/tdex

# Create a simple wrapper script that will print diagnostic info and then run the migration
COPY <<EOF /home/tdex/run.sh
#!/bin/sh
echo "===== ENVIRONMENT VARIABLES ====="
env | sort
echo "===== USER INFO ====="
whoami
echo "===== WORKING DIRECTORY ====="
pwd
echo "===== RUNNING MIGRATION WITH FIXED PASSWORD ====="
tdex-migration --password "defaultpassword" --ocean-datadir /home/tdex/.tdex-daemon/oceand
EOF

RUN chmod +x /home/tdex/run.sh

ENTRYPOINT ["/home/tdex/run.sh"]
