#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Starte Server-Provisionierung für PixelWise..."

# Den aktuellen User dynamisch ermitteln (user auf dev, produser auf prod)
CURRENT_USER=$USER

# Ordner erstellen und Rechte anpassen
sudo mkdir -p /opt/pixelwise
sudo chown -R $CURRENT_USER:$CURRENT_USER /opt/pixelwise

# System-Abhängigkeiten installieren
sudo apt update && sudo apt install -y python3.12-venv git postgresql postgresql-client-common

# Projekt klonen (falls noch nicht geschehen)
if [ ! -d "/opt/pixelwise/.git" ]; then
    sudo git clone https://github.com/TaulantM5/pixelwise.git /opt/pixelwise
    sudo chown -R $CURRENT_USER:$CURRENT_USER /opt/pixelwise
fi

# Virtuelle Umgebung auf dem Server einrichten
cd /opt/pixelwise
python3 -m venv .venv
source .venv/bin/activate

# Python-Dependencies installieren
pip install --upgrade pip
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi

# Pull the pinned model artefact
if [ -f .env ]; then
  set -a; source .env; set +a
  if [ -n "${MODEL_REPO:-}" ] && [ -n "${MODEL_VERSION:-}" ]; then
    mkdir -p models/
    rm -rf /tmp/pixelwise-model
    git clone --depth 1 --branch "$MODEL_VERSION" "$MODEL_REPO" /tmp/pixelwise-model
    cp /tmp/pixelwise-model/*.pkl models/
    cp /tmp/pixelwise-model/MODELCARD.md models/
    rm -rf /tmp/pixelwise-model
  fi
fi

echo "Server erfolgreich eingerichtet!"

# Install, start, and report the systemd unit on prod
if [ -f deploy/pixelwise.service ] && \
   command -v systemctl >/dev/null 2>&1 && \
   id produser >/dev/null 2>&1; then
    sudo cp deploy/pixelwise.service /etc/systemd/system/pixelwise.service
    sudo systemctl daemon-reload
    sudo systemctl enable pixelwise
    sudo systemctl restart pixelwise
    sudo systemctl status pixelwise --no-pager
fi

# Provision die pixelwise Rolle und Datenbank auf jeder VM
if command -v psql >/dev/null 2>&1 && [ -f "$SCRIPT_DIR/.env" ]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
  sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='pixelwise'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER pixelwise WITH PASSWORD '$DB_PASSWORD';"
  sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='pixelwise'" | grep -q 1 || \
    sudo -u postgres createdb -O pixelwise pixelwise
fi

# Install the auto-deploy systemd timer on prod
if [ -f "$SCRIPT_DIR/deploy/systemd/pixelwise-deploy.timer" ] \
   && command -v systemctl >/dev/null 2>&1 \
   && id produser >/dev/null 2>&1; then
    sudo cp "$SCRIPT_DIR/deploy/systemd/pixelwise-deploy.service" /etc/systemd/system/pixelwise-deploy.service
    sudo cp "$SCRIPT_DIR/deploy/systemd/pixelwise-deploy.timer" /etc/systemd/system/pixelwise-deploy.timer
    sudo systemctl daemon-reload
    sudo systemctl enable --now pixelwise-deploy.timer
fi
