#!/bin/bash
echo "Starte Server-Provisionierung für PixelWise..."

# Ordner erstellen und Rechte anpassen
sudo mkdir -p /opt/pixelwise
sudo chown produser:produser /opt/pixelwise

# System-Abhängigkeiten installieren
sudo apt update && sudo apt install -y python3.12-venv git

# Projekt klonen (falls noch nicht geschehen)
if [ ! -d "/opt/pixelwise/.git" ]; then
    git clone https://github.com/TaulantM5/pixelwise.git /opt/pixelwise
fi

# Virtuelle Umgebung auf dem Server einrichten
cd /opt/pixelwise
python3 -m venv .venv
source .venv/bin/activate

# Python-Dependencies installieren
pip install --upgrade pip
pip install -r requirements.txt

echo "Server erfolgreich eingerichtet!"
