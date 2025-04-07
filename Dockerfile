FROM node:16-slim

# Install necessary tools (minimal)
RUN apt-get update && apt-get install -y --fix-missing wget python3 python3-pip curl --no-install-recommends && \
    pip3 install flask && \
    rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Download oceand and tdexd binaries
RUN wget -O /usr/local/bin/oceand https://github.com/vulpemventures/ocean/releases/download/v0.2.8/ocean-v0.2.8-linux-amd64 && \
    wget -O /usr/local/bin/tdexd https://github.com/tdex-network/tdex-daemon/releases/download/v1.0.0/tdex-v1.0.0-linux-amd64 && \
    chmod +x /usr/local/bin/oceand /usr/local/bin/tdexd || true

# Create data directory
RUN mkdir -p /app/data

# Set environment variables for tdexd
ENV TDEX_WALLET_ADDR=127.0.0.1:18000
ENV TDEX_LOG_LEVEL=5
ENV TDEX_NO_MACAROONS=true
ENV TDEX_NO_OPERATOR_TLS=true
ENV TDEX_CONNECT_PROTO=http
ENV WALLET_PASSWORD=defaultpassword

# Create Flask app to serve status page with logs
RUN echo 'from flask import Flask\n\
import os\n\
import subprocess\n\
\n\
app = Flask(__name__)\n\
\n\
@app.route("/")\n\
def status():\n\
    # Get service status\n\
    oceand_running = "Running" if os.path.exists("/app/oceand.log") else "Not started"\n\
    tdexd_running = "Running" if os.path.exists("/app/tdexd.log") else "Not started"\n\
    \n\
    # Get port status\n\
    def check_port(port):\n\
        try:\n\
            result = subprocess.run(["curl", "-s", f"http://localhost:{port}"], \n\
                                   capture_output=True, text=True)\n\
            return "Responding" if result.returncode == 0 else f"Not responding (exit {result.returncode})"\n\
        except Exception as e:\n\
            return f"Error checking: {str(e)}"\n\
    \n\
    port3000 = check_port(3000)\n\
    port9000 = check_port(9000)\n\
    port9945 = check_port(9945)\n\
    port18000 = check_port(18000)\n\
    \n\
    # Get logs\n\
    oceand_log = "Log file not found"\n\
    if os.path.exists("/app/oceand.log"):\n\
        with open("/app/oceand.log", "r") as f:\n\
            oceand_log = f.read()\n\
    \n\
    tdexd_log = "Log file not found"\n\
    if os.path.exists("/app/tdexd.log"):\n\
        with open("/app/tdexd.log", "r") as f:\n\
            tdexd_log = f.read()\n\
    \n\
    # Create HTML\n\
    html = f"""\n\
    <html>\n\
    <head>\n\
        <title>TDEX Status</title>\n\
        <style>\n\
            body {{ font-family: Arial, sans-serif; margin: 20px; }}\n\
            h1 {{ color: #333; }}\n\
            h2 {{ color: #666; }}\n\
            pre {{ background-color: #f5f5f5; padding: 10px; overflow: auto; max-height: 300px; }}\n\
        </style>\n\
    </head>\n\
    <body>\n\
        <h1>TDEX Services Status</h1>\n\
        \n\
        <h2>Service Status</h2>\n\
        <p>Ocean Daemon: {oceand_running}</p>\n\
        <p>TDEX Daemon: {tdexd_running}</p>\n\
        \n\
        <h2>Port Status</h2>\n\
        <p>Port 3000: {port3000}</p>\n\
        <p>Port 9000: {port9000}</p>\n\
        <p>Port 9945: {port9945}</p>\n\
        <p>Port 18000: {port18000}</p>\n\
        \n\
        <h2>Ocean Daemon Log</h2>\n\
        <pre>{oceand_log}</pre>\n\
        \n\
        <h2>TDEX Daemon Log</h2>\n\
        <pre>{tdexd_log}</pre>\n\
    </body>\n\
    </html>\n\
    """\n\
    \n\
    return html\n\
\n\
if __name__ == "__main__":\n\
    app.run(host="0.0.0.0", port=3000)\n' > /app/app.py

# Create startup script without using chmod
RUN echo '#!/bin/sh\n\
echo "Starting Ocean daemon..."\n\
/usr/local/bin/oceand --network=regtest --datadir=/app/data --no-tls --no-profiler --db-type=badger --auto-init --auto-unlock > /app/oceand.log 2>&1 &\n\
\n\
# Wait for oceand to start\n\
echo "Waiting for Ocean daemon to start..."\n\
sleep 10\n\
\n\
# Start tdexd in the background\n\
echo "Starting TDEX daemon..."\n\
/usr/local/bin/tdexd --network=regtest --no-backup > /app/tdexd.log 2>&1 &\n\
\n\
# Wait for tdexd to start\n\
sleep 5\n\
\n\
# Start Flask web server on port 3000\n\
echo "Starting web server..."\n\
cd /app && python3 app.py\n' > /app/start.sh

# Set up entry point
ENTRYPOINT ["sh", "/app/start.sh"]

# Expose ports
EXPOSE 3000 9000 9945 18000
