#!/bin/sh

OWNER=prometheus
REPO=node_exporter

echo "Fetching the latest version of $REPO from GitHub..."
VER=$(git -c 'versionsort.suffix=-' ls-remote --tags --refs \
  --sort='-version:refname' https://github.com/$OWNER/$REPO.git \
  | head -n1 | awk -F/ '{print $3}')

# Remove 'v' prefix if present
VER=${VER#v}

echo "Latest version is $VER"
echo "Downloading and installing $REPO version $VER"

wget https://github.com/$OWNER/$REPO/releases/download/v$VER/$REPO-$VER.linux-amd64.tar.gz

if [ $? -ne 0 ]; then
  echo "Failed to download $REPO version $VER"
  exit 1
fi

# Kill existing node_exporter process if running
if pgrep -x "$REPO" >/dev/null; then
  echo "Stopping existing $REPO process"
  systemctl stop $REPO
fi

if [ -f /usr/local/bin/$REPO ]; then
  echo "Removing existing $REPO binary"
  rm -f /usr/local/bin/$REPO
fi

tar xvfz $REPO-$VER.linux-amd64.tar.gz
cd $REPO-$VER.linux-amd64
cp $REPO /usr/local/bin/
cd ..
rm -rf $REPO-$VER.linux-amd64*

if ! id -u node_exporter >/dev/null 2>&1; then
  echo "Create node_exporter user"
  useradd --no-create-home --shell /bin/false node_exporter
else
  echo "User node_exporter already exists"
fi

echo "Setting up configuration file for node_exporter with basic authentication"
if [ ! -f /etc/node_exporter/web.yml ]; then
  echo "Creating default configuration file at /etc/node_exporter/web.yml"
  mkdir -p /etc/node_exporter
  cat <<EOF >/etc/node_exporter/web.yml
# Default configuration for node_exporter
basic_auth_users:
  # username: password_hash
  # Example:
  # prometheus: node_exporter
  prometheus: $2a$12$YnamVFwW1VVHqTCAlPtH.eDJ/pIrJ2dEUW.Q47Ketq2rZVfAFkNaK

EOF
else
  echo "Configuration file /etc/node_exporter/web.yml already exists"
fi


echo "Creating systemd service file for node_exporter"
cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target 
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100 --web.config.file="/etc/node_exporter/web.yml"
[Install]
WantedBy=multi-user.target
EOF

echo "Starting node_exporter service"
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

echo "Installation complete. Please configure and start node_exporter."
systemctl status node_exporter --no-pager
echo "Node Exporter is running on port 9100"

echo "You can check the metrics at http://<your_server_ip>:9100/metrics"
echo "Remember to configure your firewall to allow traffic on port 9100 if necessary."
echo "Also, update your Prometheus configuration to scrape metrics from this node exporter."
echo "IMPORTANT: PLEASE CHANGE THE DEFAULT PASSWORD for the 'prometheus' user in /etc/node_exporter/web.yml"
echo "How to generate a bcrypt password hash: https://www.google.com/search?q=bcrypt+online+password+generator"
echo "Happy monitoring!"