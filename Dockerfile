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
mkdir -p /root/.tdex-daemon
ls -la /root
echo "===== RUNNING MIGRATION WITH FIXED PASSWORD ====="
tdex-migration --password "defaultpassword" --ocean-datadir /root/.tdex-daemon
EOF

RUN chmod +x /root/run.sh

ENTRYPOINT ["/root/run.sh"]
