FROM node:16

# Install necessary tools
WORKDIR /app
RUN apt-get update && apt-get install -y git wget supervisor

# Clone the dashboard repository
RUN git clone --depth 1 --branch v1 https://github.com/thedopecompany/tdex-dashboard.git /app/dashboard

# Install dashboard dependencies and build it
WORKDIR /app/dashboard
RUN yarn install
RUN yarn build

# Download and install oceand (latest version)
WORKDIR /app
RUN wget -O /usr/local/bin/oceand https://github.com/vulpemventures/ocean/releases/download/v0.2.8/ocean-v0.2.8-linux-amd64

# Download and install tdexd
RUN wget -O /usr/local/bin/tdexd https://github.com/tdex-network/tdex-daemon/releases/download/v1.0.0/tdex-v1.0.0-linux-amd64

# Install a simple HTTP server for the dashboard
RUN npm install -g serve

# Set up supervisor to manage all processes
RUN mkdir -p /etc/supervisor/conf.d

# Create supervisor configuration
RUN echo '[supervisord]\n\
nodaemon=true\n\
\n\
[program:oceand]\n\
command=/usr/local/bin/oceand --network=regtest --datadir=/app/data --no-tls --no-profiler --db-type=badger --auto-init --auto-unlock\n\
autostart=true\n\
autorestart=true\n\
stderr_logfile=/var/log/oceand.err.log\n\
stdout_logfile=/var/log/oceand.out.log\n\
\n\
[program:tdexd]\n\
command=/usr/local/bin/tdexd --network=regtest --no-backup\n\
environment=TDEX_WALLET_ADDR="127.0.0.1:18000",TDEX_LOG_LEVEL="5",TDEX_NO_MACAROONS="true",TDEX_NO_OPERATOR_TLS="true",TDEX_CONNECT_PROTO="http",WALLET_PASSWORD="defaultpassword"\n\
autostart=true\n\
autorestart=true\n\
stderr_logfile=/var/log/tdexd.err.log\n\
stdout_logfile=/var/log/tdexd.out.log\n\
\n\
[program:dashboard]\n\
command=serve -s /app/dashboard/build -l 3000\n\
autostart=true\n\
autorestart=true\n\
stderr_logfile=/var/log/dashboard.err.log\n\
stdout_logfile=/var/log/dashboard.out.log' > /etc/supervisor/conf.d/supervisord.conf

# Create data directory
RUN mkdir -p /app/data

# Set environment variables for the dashboard
ENV REACT_APP_BASENAME=/
ENV REACT_APP_TLS_ENABLED=false
ENV REACT_APP_MACAROON_ENABLED=false
ENV REACT_APP_GRPCWEB_HOSTNAME=localhost
ENV REACT_APP_GRPCWEB_PORT=9945

# Expose ports
EXPOSE 3000 9000 9945 18000

# Start supervisord to manage all services
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
