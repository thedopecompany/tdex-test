FROM ghcr.io/tdex-network/tdexd:latest

# Set up environment (environment variables will be injected from Render)
ENV DATA_DIR=/var/data

# Create a simple wrapper script to print debug info and then run the command
USER root
WORKDIR /root

# Create a simple wrapper script that will print diagnostic info and then run the migration
COPY <<EOF /root/run.sh
#!/bin/sh
echo "===== ENVIRONMENT VARIABLES ====="
env | sort
echo "===== USER INFO ====="
whoami
echo "===== WORKING DIRECTORY ====="
pwd
echo "===== DIRECTORY CHECK ====="

# Create all required directories
mkdir -p /root/.tdex-daemon
mkdir -p /root/.tdex-daemon/db/main
ls -la /root
ls -la /root/.tdex-daemon

# Create a completely fresh directory for ocean data
FRESH_OCEAN_DIR="/tmp/fresh_ocean_dir"
echo "===== PREPARING FRESH DIRECTORY ====="
rm -rf "\$FRESH_OCEAN_DIR"
mkdir -p "\$FRESH_OCEAN_DIR"
ls -la "\$FRESH_OCEAN_DIR"

echo "===== RUNNING MIGRATION WITH FRESH DIRECTORY ====="
tdex-migration --password "defaultpassword" --ocean-datadir "\$FRESH_OCEAN_DIR"
EOF

RUN chmod +x /root/run.sh

ENTRYPOINT ["/root/run.sh"]
