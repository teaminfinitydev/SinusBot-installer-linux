
#!/bin/bash
# Fixed SinusBot installer for modern Ubuntu versions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

function greenMessage() {
  echo -e "${GREEN}${*}${NC}"
}

function redMessage() {
  echo -e "${RED}${*}${NC}"
}

function yellowMessage() {
  echo -e "${YELLOW}${*}${NC}"
}

function cyanMessage() {
  echo -e "${CYAN}${*}${NC}"
}

# Check if running as root
if [ "$(id -u)" != "0" ]; then
  redMessage "This script must be run as root!"
  exit 1
fi

greenMessage "Fixed SinusBot Installer for Modern Ubuntu"
greenMessage "========================================="

# Update system
yellowMessage "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# Install dependencies with correct package names for modern Ubuntu
yellowMessage "Installing dependencies..."
apt-get install -y -qq --no-install-recommends \
  libfontconfig1 \
  libxtst6 \
  screen \
  xvfb \
  libxcursor1 \
  ca-certificates \
  bzip2 \
  psmisc \
  libglib2.0-0t64 \
  less \
  python3 \
  iproute2 \
  dbus \
  libnss3 \
  libegl1-mesa0 \
  x11-xkb-utils \
  libasound2t64 \
  libxcomposite-dev \
  libxi6 \
  libpci3 \
  libxslt1.1 \
  libxkbcommon0 \
  libxss1 \
  wget \
  curl \
  ntp

# Additional dependencies that might be needed
apt-get install -y -qq \
  libx11-6 \
  libxrandr2 \
  libxdamage1 \
  libdrm2 \
  libgbm1 \
  libgtk-3-0t64 \
  libatk-bridge2.0-0t64 \
  libatk1.0-0

greenMessage "Dependencies installed successfully!"

# Set up time synchronization
yellowMessage "Setting up time synchronization..."
if command -v timedatectl >/dev/null 2>&1; then
  timedatectl set-ntp yes
  systemctl restart systemd-timesyncd
  greenMessage "Time synchronization configured"
else
  service ntp restart
  greenMessage "NTP service restarted"
fi

# Create SinusBot user
SINUSBOTUSER="sinusbot"
yellowMessage "Creating SinusBot user: $SINUSBOTUSER"

if ! id "$SINUSBOTUSER" &>/dev/null; then
  useradd -m -s /bin/bash "$SINUSBOTUSER"
  greenMessage "User $SINUSBOTUSER created successfully"
else
  greenMessage "User $SINUSBOTUSER already exists"
fi

# Set installation directory
LOCATION="/opt/sinusbot"
yellowMessage "Installation directory: $LOCATION"

# Create directory and set permissions
mkdir -p "$LOCATION"
chmod 750 "$LOCATION"
chown -R "$SINUSBOTUSER:$SINUSBOTUSER" "$LOCATION"

# Download and install TeamSpeak Client
cd "$LOCATION"
yellowMessage "Downloading TeamSpeak 3 Client..."

TS_VERSION="3.6.2"
TS_URL="https://files.teamspeak-services.com/releases/client/$TS_VERSION/TeamSpeak3-Client-linux_amd64-$TS_VERSION.run"

if [ ! -f "teamspeak3-client/ts3client_linux_amd64" ]; then
  mkdir -p teamspeak3-client
  cd teamspeak3-client
  
  su -c "wget -q '$TS_URL'" "$SINUSBOTUSER"
  
  if [ -f "TeamSpeak3-Client-linux_amd64-$TS_VERSION.run" ]; then
    chmod +x "TeamSpeak3-Client-linux_amd64-$TS_VERSION.run"
    
    # Auto-accept TeamSpeak license
    greenMessage "Installing TeamSpeak Client..."
    su -c "echo 'y' | ./TeamSpeak3-Client-linux_amd64-$TS_VERSION.run" "$SINUSBOTUSER"
    
    # Copy files and clean up
    if [ -d "TeamSpeak3-Client-linux_amd64" ]; then
      cp -R ./TeamSpeak3-Client-linux_amd64/* ./
      rm -rf ./TeamSpeak3-Client-linux_amd64
      rm -f "./TeamSpeak3-Client-linux_amd64-$TS_VERSION.run"
      rm -f ./ts3client_runscript.sh
    fi
    
    # Create plugins directory
    mkdir -p plugins
    
    # Remove problematic Qt libraries
    rm -f libQt5WebEngineCore.so.5 libQt5WebEngine.so.5 libQt5WebEngineWidgets.so.5
    rm -f xcbglintegrations/libqxcb-glx-integration.so 2>/dev/null
    
    greenMessage "TeamSpeak Client installed successfully"
  else
    redMessage "Failed to download TeamSpeak Client"
    exit 1
  fi
else
  greenMessage "TeamSpeak Client already installed"
fi

# Download and install SinusBot
cd "$LOCATION"
yellowMessage "Downloading SinusBot..."

su -c "wget -q https://www.sinusbot.com/dl/sinusbot.current.tar.bz2" "$SINUSBOTUSER"

if [ -f "sinusbot.current.tar.bz2" ]; then
  greenMessage "Extracting SinusBot..."
  su -c "tar -xjf sinusbot.current.tar.bz2" "$SINUSBOTUSER"
  rm -f sinusbot.current.tar.bz2
  chmod 755 sinusbot
  
  # Copy plugin to TeamSpeak directory
  if [ -f "plugin/libsoundbot_plugin.so" ]; then
    cp plugin/libsoundbot_plugin.so teamspeak3-client/plugins/
  fi
  
  greenMessage "SinusBot installed successfully"
else
  redMessage "Failed to download SinusBot"
  exit 1
fi

# Create config.ini
yellowMessage "Creating configuration file..."
cat > config.ini << 'EOF'
ListenPort = 8087
ListenHost = "0.0.0.0"
TS3Path = "/opt/sinusbot/teamspeak3-client/ts3client_linux_amd64"
YoutubeDLPath = "/usr/local/bin/youtube-dl"
LogLevel = 10
LocalPlayback = false
EnableLocalFS = false
MaxBulkOperations = 300
EnableProfiler = false
EnableDebugConsole = false
AllowStreamPush = false
UploadLimit = 83886080
RunAsUser = 0
RunAsGroup = 0
InstanceActionLimit = 6
UseSSL = false
SSLKeyFile = ""
SSLCertFile = ""
Hostname = ""
SampleRate = 44100
StartVNC = false
EnableWebStream = false
LogFile = ""
LicenseKey = ""
IsProxied = false
DenyStreamURLs = []
Pragma = 0

[YoutubeDL]
Enabled = true
BufferSize = 524288
MaxDownloadSize = 41943040
MaxDownloadRate = 104857600
MaxSimultaneousChunkedDownloads = 6
ChunkedDownloadConnectionsPerDownload = 3
TimeoutSingleDownloadMilliseconds = 0
TimeoutMultiDownloadMilliseconds = 0
MaxParallelDownloads = 2

[TTS]

[Webinterface]
Whitelist = "127.0.0.1"
EOF

# Install YouTube-DL
yellowMessage "Installing YouTube-DL..."
wget -q https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/youtube-dl
chmod a+rx /usr/local/bin/youtube-dl

# Create YouTube-DL update cronjob
echo "0 0 * * * $SINUSBOTUSER PATH=\$PATH:/usr/local/bin; youtube-dl -U --restrict-filename >/dev/null" > /etc/cron.d/ytdl

greenMessage "YouTube-DL installed successfully"

# Create systemd service
yellowMessage "Creating systemd service..."
cat > /lib/systemd/system/sinusbot.service << EOF
[Unit]
Description=SinusBot
After=network.target

[Service]
Type=forking
User=$SINUSBOTUSER
Group=$SINUSBOTUSER
ExecStart=$LOCATION/sinusbot --daemon
WorkingDirectory=$LOCATION
TimeoutSec=15
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Enable and configure service
systemctl daemon-reload
systemctl enable sinusbot.service

# Set final permissions
chown -R "$SINUSBOTUSER:$SINUSBOTUSER" "$LOCATION"
chmod 755 "$LOCATION/sinusbot"

# Clean up temporary files
if [ -f /tmp/.sinusbot.lock ]; then
  rm /tmp/.sinusbot.lock
fi

if [ -e /tmp/.X11-unix/X40 ]; then
  rm /tmp/.X11-unix/X40
fi

# Initialize SinusBot for first run
yellowMessage "Initializing SinusBot..."
cd "$LOCATION"

# Run initial setup to get admin password
INIT_OUTPUT=$(su -c './sinusbot --initonly 2>&1' "$SINUSBOTUSER")
PASSWORD=$(echo "$INIT_OUTPUT" | grep -oP "password '\K[^']+")

if [ -z "$PASSWORD" ]; then
  # Try alternative method
  PASSWORD=$(su -c './sinusbot --initonly 2>&1' "$SINUSBOTUSER" | grep -i password | sed "s/.*password '\([^']*\)'.*/\1/")
fi

# Start SinusBot
yellowMessage "Starting SinusBot service..."
systemctl start sinusbot

# Wait for startup
sleep 5

# Check if service is running
if systemctl is-active --quiet sinusbot; then
  greenMessage "======================================="
  greenMessage "SinusBot Installation Complete!"
  greenMessage "======================================="
  greenMessage "Web Interface: http://$(ip route get 8.8.8.8 | awk '{print $7; exit}'):8087"
  if [ -n "$PASSWORD" ]; then
    greenMessage "Admin User: admin"
    greenMessage "Admin Password: $PASSWORD"
  else
    yellowMessage "Please check the logs for the admin password:"
    yellowMessage "journalctl -u sinusbot -f"
  fi
  greenMessage ""
  greenMessage "Service Commands:"
  greenMessage "Start: systemctl start sinusbot"
  greenMessage "Stop: systemctl stop sinusbot"
  greenMessage "Restart: systemctl restart sinusbot"
  greenMessage "Status: systemctl status sinusbot"
  greenMessage "Logs: journalctl -u sinusbot -f"
  greenMessage ""
  greenMessage "Configuration file: $LOCATION/config.ini"
  greenMessage "======================================="
else
  redMessage "SinusBot failed to start. Check logs with:"
  redMessage "journalctl -u sinusbot -f"
  redMessage "Or try running manually:"
  redMessage "cd $LOCATION && su -c './sinusbot' $SINUSBOTUSER"
fi
