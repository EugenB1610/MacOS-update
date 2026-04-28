#!/usr/bin/env bash
set -euo pipefail

# --- Konfiguration ---
# Farben für den Terminal-Ausgang (falls Terminal-Farbunterstützung vorhanden)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Hilfsfunktion für den Output (ähnlich wie V1, aber mit Emoji) ---
output() {
    local msg=$1
    # Wenn man Farben mag, fügt sie hinzu, sonst nur Text
    if [[ -t 2 ]]; then
        printf "${GREEN}✅ ${msg}${NC}\n"
    else
        echo "✅ ${msg}"
    fi
}

warn() {
    if [[ -t 2 ]]; then
        printf "${YELLOW}⚠️  ${1}${NC}\n"
    else
        echo "⚠️  $1"
    fi
}

error() {
    if [[ -t 2 ]]; then
        printf "${RED}❌ ${1}${NC}\n"
    else
        echo "❌ $1"
    fi
}

# --- Ja/Nein-Frage (Robust wie in V1, aber einfacher implementiert) ---
ask_yes_no() {
    local prompt=$1
    read -rp "$prompt" reply
    # Akzeptiert y/n/yes/no
    case $reply in
        [YyJj]* ) return 0 ;;
        [Nn]* ) return 1 ;;
        * ) warn "Bitte nur 'y' oder 'n' eingeben."
              read -rp "$prompt" reply ;;
    esac
}

# --- Hauptlogik ---

echo "--- 🚀 Starte MacBook Update ---"
output "--- 🚀 Homebrew-Index aktualisieren"
brew update
output "✅ Index aktualisiert."

output "--- 📦 Formeln und Casks upgraden ---"
brew upgrade

# Casks prüfen
if brew tap | grep -q 'buo/cask-upgrade'; then
    output "🖥️  Verwende brew-cu für Casks..."
    brew cu -a -y --cleanup --quiet
else
    output "🖥️  Verwende Standard-Upgrade für Casks..."
    brew upgrade --cask --greedy
fi

# Mas (App Store)
if command -v mas >/dev/null 2>&1; then
    output "--- 🍎 Suche nach Mac App Store Updates ---"
    if ask_yes_no "🍎 Möchtest du Mac App Store Updates suchen? (y/n): "; then
        mas upgrade
        output "✅ App Store Updates gefunden und installiert."
    else
        warn "App Store Updates wurden übersprungen."
    fi
else
    warn "'mas' nicht gefunden – App Store Updates übersprungen."
fi

output "--- 🧹 Bereinige Homebrew-Cache ---"
start=$(date +%s)

brew cleanup --prune=all --quiet # Aggressives Aufräumen
output "✅ Bereinigung abgeschlossen."

end=$(date +%s)
elapsed=$((end - start))
output "--- Update abgeschlossen! Dauer: ${elapsed}s ---"

echo ""
echo "👋 Auf Wiedersehen, Eugen! Hab einen schönen Tag."

# Fenster schließen
echo "Drücke [Enter], um zu beenden..."
read -r
