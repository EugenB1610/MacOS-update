#!/usr/bin/env bash
# Wir nutzen -u (unbound variables) und -o pipefail, 
# aber lassen -e weg, damit das Skript bei einem Fehlerszenario eines einzelnen Pakets nicht komplett abbricht.
set -uo pipefail

# --- Konfiguration ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Hilfsfunktion für den Output ---
output() {
    local msg=$1
    if [[ -t 1 ]]; then
        printf "${GREEN}✅ %s${NC}\n" "$msg"
    else
        echo "✅ $msg"
    fi
}

warn() {
    if [[ -t 1 ]]; then
        printf "${YELLOW}⚠️  %s${NC}\n" "$1"
    else
        echo "⚠️  $1"
    fi
}

error() {
    if [[ -t 1 ]]; then
        printf "${RED}❌ %s${NC}\n" "$1"
    else
        echo "❌ $1"
    fi
}

# --- Ja/Nein-Frage ---
ask_yes_no() {
    local prompt=$1
    read -rp "$prompt" reply
    case $reply in
        [YyJj]* ) return 0 ;;
        [Nn]* ) return 1 ;;
        * ) warn "Bitte nur 'y' oder 'n' eingeben."
              read -rp "$prompt" reply ;;
    esac
}

# --- Hauptlogik ---

# 1. Check ob Homebrew existiert
if ! command -v brew >/dev/null 2>&1; then
    error "Homebrew wurde nicht gefunden! Bitte installiere es zuerst: https://brew.sh/"
    exit 1
fi

echo "--- 🚀 Starte MacBook Update ---"

output "--- 🚀 Home\\nIndex aktualisieren"
brew update || true
output "✅ Index aktualisiert."

output "--- 📦 Formeln und Casks upgraden"
# Wir lassen das Skript weiterlaufen, falls ein Paket mal Probleme macht
brew upgrade || true

# Casks prüfen
if brew tap | grep -q 'buo/cask-upgrade'; then
    output "🖥️  Verwende brew-cu für Casks..."
    brew cu -a -y --cleanup --quiet || true
else
    output "🖥️  Verwende Standard-Upgrade für Casks..."
    brew upgrade --cask --greedy || true
fi

# Mas (App Store)
if command -v mas >/dev/null 2>&1; then
    output "--- 🍎 Suche nach Mac App Store Updates ---"
    if ask_yes_no "🍎 Möchtest du Mac App Store Updates suchen? (y/n): "; then
        mas upgrade || true
        output "✅ App Store Update-Prozess beendet."
    else
        warn "App Store Updates wurden übersprungen."
    fi
else
    warn "'mas' nicht gefunden – App Store Updates übersprungen."
fi

output "--- 🧹 Bereinige Homebrew-Cache ---"
start=$(date +%s)

brew cleanup --prune=all --quiet || true
output "✅ Bereinigung abgeschlossen."

end=$(date +%s)
elapsed=$((end - start))
output "--- Update abgeschlossen! Dauer: ${elapsed}s ---"

echo ""
echo "👋 Auf Wiedersehen, Eugen! Hab einen schönen Tag."

# Fenster schließen
echo "Drücke [Enter], um zu beenden..."
read -r
