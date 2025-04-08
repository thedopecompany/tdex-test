FROM node:16-slim

# Install necessary tools
RUN apt-get update && apt-get install -y git wget python3 python3-pip --no-install-recommends && \
    pip3 install requests && \
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

# Create Python reverse proxy script
RUN echo 'import http.server\n\
import socketserver\n\
import requests\n\
import json\n\
\n\
class ProxyHandler(http.server.SimpleHTTPRequestHandler):\n\
    def do_GET(self):\n\
        target_url = f"http://localhost:9000{self.path}"\n\
        try:\n\
            response = requests.get(target_url)\n\
            self.send_response(response.status_code)\n\
            for header, value in response.headers.items():\n\
                self.send_header(header, value)\n\
            self.end_headers()\n\
            self.wfile.write(response.content)\n\
        except Exception as e:\n\
            self.send_response(502)\n\
            self.send_header("Content-type", "application/json")\n\
            self.end_headers()\n\
            self.wfile.write(json.dumps({"error": str(e)}).encode())\n\
\n\
    def do_POST(self):\n\
        content_length = int(self.headers.get("Content-Length", 0))\n\
        body = self.rfile.read(content_length) if content_length else None\n\
        target_url = f"http://localhost:9000{self.path}"\n\
        try:\n\
            response = requests.post(target_url, data=body, headers=self.headers)\n\
            self.send_response(response.status_code)\n\
            for header, value in response.headers.items():\n\
                self.send_header(header, value)\n\
            self.end_headers()\n\
            self.wfile.write(response.content)\n\
        except Exception as e:\n\
            self.send_response(502)\n\
            self.send_header("Content-type", "application/json")\n\
            self.end_headers()\n\
            self.wfile.write(json.dumps({"error": str(e)}).encode())\n\
\n\
print("Starting proxy server on port 80...")\n\
with socketserver.TCPServer(("", 80), ProxyHandler) as httpd:\n\
    httpd.serve_forever()\n\
' > /app/proxy.py

# Create startup script
RUN echo '#!/bin/sh\n\
echo "Starting Ocean daemon..."\n\
/usr/local/bin/oceand --network=regtest --datadir=/app/data --no-tls --no-profiler --db-type=badger --auto-init --auto-unlock > /app/oceand.log 2>&1 &\n\
\n\
# Wait for oceand to start\n\
echo "Waiting for Ocean daemon to start..."\n\
sleep 10\n\
\n\
# Start tdexd in the background with explicit bind address\n\
echo "Starting TDEX daemon..."\n\
/usr/local/bin/tdexd --network=regtest --no-backup --api.addr=0.0.0.0:9000 > /app/tdexd.log 2>&1 &\n\
\n\
# Wait for services to start\n\
echo "Waiting for services to start..."\n\
sleep 10\n\
\n\
# Start Python proxy server\n\
echo "Starting proxy server..."\n\
python3 /app/proxy.py\n' > /app/start.sh

# Set up entry point
ENTRYPOINT ["sh", "/app/start.sh"]

# Expose ports
EXPOSE 80 9000 9945 18000
