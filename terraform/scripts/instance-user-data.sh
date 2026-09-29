#!/bin/bash
# Bootstrap for the single-instance version. Runs both the backend app and
# Nginx on one host. The app binds to 127.0.0.1 only, so it has no network
# exposure at all -- not even within the VPC -- regardless of security group
# rules. This substitutes for the network-level isolation the two-instance
# version got from a private subnet.
set -euxo pipefail

# ---------- Backend app ----------

mkdir -p /opt/app

cat > /opt/app/app.py <<'PYEOF'
import json
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps(
            {
                "message": "Hello from the backend app (same host as Nginx)",
                "hostname": socket.gethostname(),
                "path": self.path,
                "client_seen_by_app": self.client_address[0],
                "x_forwarded_for": self.headers.get("X-Forwarded-For"),
                "x_real_ip": self.headers.get("X-Real-IP"),
                "host_header": self.headers.get("Host"),
            },
            indent=2,
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    # 127.0.0.1, not 0.0.0.0: only reachable from this same instance.
    HTTPServer(("127.0.0.1", ${app_port}), Handler).serve_forever()
PYEOF

cat > /etc/systemd/system/app.service <<'UNITEOF'
[Unit]
Description=Demo backend app
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
UNITEOF

systemctl daemon-reload
systemctl enable --now app.service

# ---------- Nginx ----------

dnf install -y nginx

cat > /etc/nginx/nginx.conf <<'NGINXEOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80 default_server;
        server_name _;

        location / {
            proxy_pass http://127.0.0.1:${app_port};

            proxy_set_header Host              $host;
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_connect_timeout 5s;
            proxy_read_timeout    30s;
        }

        location = /nginx-health {
            access_log off;
            default_type text/plain;
            return 200 "ok\n";
        }
    }
}
NGINXEOF

nginx -t
systemctl enable --now nginx