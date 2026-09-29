#!/bin/bash
# Bootstrap for the private backend app. Uses only python3, which is
# preinstalled on Amazon Linux 2023, because this subnet has no internet access.
set -euxo pipefail

mkdir -p /opt/app

cat > /opt/app/app.py <<'PYEOF'
import json
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps(
            {
                "message": "Hello from the private app server",
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
    HTTPServer(("0.0.0.0", ${app_port}), Handler).serve_forever()
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