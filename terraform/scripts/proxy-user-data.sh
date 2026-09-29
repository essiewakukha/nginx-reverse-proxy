#!/bin/bash
set -euxo pipefail

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
            proxy_pass http://${app_private_ip}:${app_port};

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
