#!/bin/bash
set -e

# Standalone installer: nginx (reverse proxy) + fail2ban for a system
# where o11 is already installed and running on 127.0.0.1:8283.

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info()  { printf "${CYAN}==>${NC} %b\n" "$*"; }
log_ok()    { printf "${GREEN}✓${NC} %b\n" "$*"; }
log_warn()  { printf "${BOLD}${CYAN}!${NC} %b\n" "$*"; }
log_error() { printf "${RED}✗${NC} %b\n" "$*" >&2; }
log_dim()   { printf "${DIM}%b${NC}\n" "$*"; }
log_title() { printf "\n${BOLD}${GREEN}%b${NC}\n" "$*"; }

log_title "Removing existing o11.service"
systemctl stop o11.service 2>/dev/null || true
rm -f /etc/systemd/system/o11.service
log_ok "o11.service stopped and removed"

log_title "Installing nginx and fail2ban"
apt update
apt install -y nginx-full fail2ban
log_ok "Packages installed"

log_title "Configuring nginx"
NGINX_DEFAULT_SITE=/etc/nginx/sites-enabled/default
NGINX_O11_SITE=/etc/nginx/sites-enabled/o11
if [ -f "$NGINX_DEFAULT_SITE" ]; then
  sed -i \
    -e 's/listen 80 default_server;/listen 8080 default_server;/' \
    -e 's/listen \[::\]:80 default_server;/listen [::]:8080 default_server;/' \
    "$NGINX_DEFAULT_SITE"
  log_ok "Nginx default site changed to port 8080"
else
  log_warn "$NGINX_DEFAULT_SITE not found — skipping"
fi

cat <<'EOL' > "$NGINX_O11_SITE"
log_format o11_proxy '$remote_addr - [$time_local] "$request" $status';

server {
  listen 8234;
  listen [::]:8234;

  access_log /var/log/nginx/o11_proxy.log o11_proxy;

  location /stream/ {
    access_log off;
    proxy_pass http://127.0.0.1:8283;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location / {
    proxy_pass http://127.0.0.1:8283;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
EOL
log_ok "Nginx O11 site listens on 8234 and forwards to 127.0.0.1:8283"

nginx -t && systemctl reload nginx || systemctl restart nginx
systemctl enable nginx
log_ok "nginx configured and running"

log_title "Rewriting /etc/systemd/system/o11.service"
cat <<EOL > /etc/systemd/system/o11.service
[Unit]
Description=Auto-start O11 Streammer
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
ExecStart=/home/o11/o11 -p 8283 -b 127.0.0.1 -noramfs
WorkingDirectory=/home/o11/
User=o11
Restart=always
RestartSec=5s

StandardOutput=journal
StandardError=journal
SyslogIdentifier=o11

[Install]
WantedBy=multi-user.target
EOL
log_ok "o11.service overwritten"

systemctl daemon-reload
systemctl enable --now o11.service
log_ok "o11.service reloaded and restarted"

systemctl restart nginx.service
log_ok "nginx.service reloaded and restarted"

log_title "Configuring fail2ban"
cat <<'EOL' > /etc/fail2ban/filter.d/nginx-o11-401.conf
[Definition]
failregex = ^<HOST> - \[.*\] ".*" 401$
ignoreregex =
EOL
log_ok "nginx-o11-401 filter created"

cat <<'EOL' > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
findtime = 10m
bantime = 1h

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
backend = polling
maxretry = 5
findtime = 10m
bantime = 1d
banaction = ufw

[nginx-o11-401]
enabled = true
filter = nginx-o11-401
port = 8234
logpath = /var/log/nginx/o11_proxy.log
backend = polling
maxretry = 5
findtime = 10m
bantime = 24h
banaction = ufw
EOL
systemctl enable --now fail2ban
systemctl restart fail2ban
log_ok "fail2ban configured and started"

if command -v ufw >/dev/null 2>&1; then
  log_title "Updating firewall (ufw)"
  ufw allow 8234/tcp
  log_ok "Allowed port 8234/tcp"
else
  log_warn "ufw not found — skipping firewall rule"
fi


log_title "Done!"
log_dim "  sudo systemctl status nginx"
log_dim "  sudo systemctl status fail2ban"
log_dim "  sudo fail2ban-client status"
