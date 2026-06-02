#!/bin/bash
echo "Starte PixelWise Build-Prozess..."

# Prüfen, ob die virtuelle Umgebung existiert und aktivieren
if [ -d ".venv" ]; then
    source .venv/bin/activate
    echo "Virtuelle Umgebung (.venv) aktiviert."
fi

# Dependencies installieren
echo "Aktualisiere Dependencies..."
pip install -r requirements.txt

echo "Build erfolgreich abgeschlossen!"
