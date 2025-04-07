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

# Use a unique random directory to avoid any conflicts
FRESH_OCEAN_DIR="/tmp/ocean_\$(date +%s)_\$RANDOM"
echo "===== PREPARING FRESH DIRECTORY ====="
mkdir -p "\$FRESH_OCEAN_DIR"
ls -la "\$FRESH_OCEAN_DIR"

echo "===== CHECKING TDEX-MIGRATION ====="
which tdex-migration
tdex-migration --help

echo "===== RUNNING MIGRATION WITH FRESH DIRECTORY ====="
# Try with additional parameters to force overwrite
tdex-migration --password "defaultpassword" --ocean-datadir "\$FRESH_OCEAN_DIR" --force 2>&1

# If that fails, try running the daemon directly
if [ $? -ne 0 ]; then
    echo "===== MIGRATION FAILED, TRYING DIRECT DAEMON START ====="
    tdexd --network regtest --datadir /root/.tdex-daemon --ocean-datadir "\$FRESH_OCEAN_DIR" 2>&1
fi
EOF

RUN chmod +x /root/run.sh

ENTRYPOINT ["/root/run.sh"]
