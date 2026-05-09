#!/bin/sh

OWNER=prometheus
REPO=node_exporter

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

# Get the server's public IPv4 address
PUBLIC_IP=$(curl -4 -s ifconfig.me)

log_title "Fetching the latest version of $REPO from GitHub..."
VER=$(git -c 'versionsort.suffix=-' ls-remote --tags --refs \
  --sort='-version:refname' https://github.com/$OWNER/$REPO.git \
  | head -n1 | awk -F/ '{print $3}')

# Remove 'v' prefix if present
VER=${VER#v}

if [ -z "$VER" ]; then
  log_error "Could not determine the latest version of $REPO"
  exit 1
fi

log_ok "Latest version is ${BOLD}$VER${NC}"

# Detect existing installation and version
INSTALLED_VER=""
if [ -x /usr/local/bin/$REPO ]; then
  INSTALLED_VER=$(/usr/local/bin/$REPO --version 2>&1 | head -n1 | awk '{print $3}')
  log_info "Detected existing $REPO version: ${BOLD}${INSTALLED_VER:-unknown}${NC}"
  if [ "$INSTALLED_VER" = "$VER" ]; then
    log_warn "Already at latest version — re-installing to ensure consistency."
  else
    log_info "Updating ${INSTALLED_VER:-unknown} → ${BOLD}$VER${NC}"
  fi
fi

log_info "Downloading $REPO version $VER"
wget -q --show-progress https://github.com/$OWNER/$REPO/releases/download/v$VER/$REPO-$VER.linux-amd64.tar.gz

if [ $? -ne 0 ]; then
  log_error "Failed to download $REPO version $VER"
  exit 1
fi

# Stop existing service / process if running
if systemctl is-active --quiet $REPO 2>/dev/null; then
  log_info "Stopping existing $REPO service"
  systemctl stop $REPO
elif pgrep -x "$REPO" >/dev/null; then
  log_info "Killing existing $REPO process"
  pkill -x "$REPO" || true
fi

if [ -f /usr/local/bin/$REPO ]; then
  log_info "Removing existing $REPO binary"
  rm -f /usr/local/bin/$REPO
fi

log_info "Extracting and installing $REPO binary"
tar xfz $REPO-$VER.linux-amd64.tar.gz
cd $REPO-$VER.linux-amd64
cp $REPO /usr/local/bin/
cd ..
rm -rf $REPO-$VER.linux-amd64*
log_ok "$REPO binary installed at /usr/local/bin/$REPO"

if ! id -u node_exporter >/dev/null 2>&1; then
  log_info "Creating node_exporter user"
  useradd --no-create-home --shell /bin/false node_exporter
  log_ok "User node_exporter created"
else
  log_dim "User node_exporter already exists — skipping"
fi

log_info "Setting up configuration file for node_exporter with basic authentication"
mkdir -p /etc/node_exporter
if [ ! -f /etc/node_exporter/web.yml ]; then
  log_info "Creating default configuration file at /etc/node_exporter/web.yml"
  # NOTE: quoted 'EOF' prevents the shell from expanding $2a$12$... in the bcrypt hash
  cat <<'EOF' >/etc/node_exporter/web.yml
# Default configuration for node_exporter
# How to generate a bcrypt password hash: https://www.google.com/search?q=bcrypt+online+password+generator
basic_auth_users:
  # username: prometheus
  # password: IamYoung
  # prometheus: node_exporter
  prometheus: $2a$12$YnamVFwW1VVHqTCAlPtH.eDJ/pIrJ2dEUW.Q47Ketq2rZVfAFkNaK

EOF
  chown node_exporter:node_exporter /etc/node_exporter/web.yml
  chmod 640 /etc/node_exporter/web.yml
  log_ok "Default web.yml created"
else
  log_dim "Configuration file /etc/node_exporter/web.yml already exists — preserving user settings"
fi

log_info "Writing systemd service file for node_exporter (overwrite if exists)"
cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Restart=always
RestartSec=5s

StandardOutput=journal
StandardError=journal
SyslogIdentifier=node_exporter

User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100 --web.config.file="/etc/node_exporter/web.yml"

[Install]
WantedBy=multi-user.target
EOF
log_ok "Systemd service file written"

log_info "Reloading systemd and (re)starting node_exporter service"
systemctl daemon-reload
systemctl enable node_exporter >/dev/null 2>&1
systemctl restart node_exporter

log_title "Installation complete"
systemctl status node_exporter --no-pager

log_ok "Node Exporter is running on port ${BOLD}9100${NC}"
log_info "Metrics endpoint: ${BOLD}http://$PUBLIC_IP:9100/metrics${NC}"
log_warn "Remember to configure your firewall to allow traffic on port 9100 if necessary."
log_warn "Update your Prometheus configuration to scrape metrics from this node exporter."
printf "${RED}${BOLD}IMPORTANT:${NC} ${RED}Please CHANGE THE DEFAULT PASSWORD for the 'prometheus' user in /etc/node_exporter/web.yml${NC}\n"
log_dim "How to generate a bcrypt password hash: https://www.google.com/search?q=bcrypt+online+password+generator"
printf "${GREEN}${BOLD}Happy monitoring!${NC}\n"