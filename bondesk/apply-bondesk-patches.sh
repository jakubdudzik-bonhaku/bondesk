#!/usr/bin/env bash
# Applies BonDesk branding + embedded server/key on top of rustdesk source.
# Run from repo root.
set -euo pipefail

BD="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$BD/.." && pwd)"
cd "$ROOT"

echo "==> BonDesk patches: embedding server + key into hbb_common"
CFG="libs/hbb_common/src/config.rs"
test -f "$CFG" || { echo "ERR: $CFG missing - submodule not initialized?"; exit 1; }

# RENDEZVOUS_SERVERS - jeden lub wiele (oddzielone ", ")
sed -i 's|^pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[.*\];$|pub const RENDEZVOUS_SERVERS: \&[\&str] = \&["57.129.120.80"];|' "$CFG"
# RS_PUB_KEY
sed -i 's|^pub const RS_PUB_KEY: &str = .*;$|pub const RS_PUB_KEY: \&str = "QKHqfXkX7+OR3fkVlIfhFvCpwqfz1xpTI5iqfqYCDxo=";|' "$CFG"

echo "    verifying patches:"
grep -E '^pub const (RENDEZVOUS_SERVERS|RS_PUB_KEY)' "$CFG"

echo "==> BonDesk patches: replacing icons"
cp -v "$BD/branding/icon.ico"     res/icon.ico
cp -v "$BD/branding/icon.ico"     res/tray-icon.ico
cp -v "$BD/branding/logo-512.png" res/icon.png
cp -v "$BD/branding/logo-128.png" res/128x128.png
cp -v "$BD/branding/logo-256.png" res/128x128@2x.png
cp -v "$BD/branding/logo-32.png"  res/32x32.png
cp -v "$BD/branding/logo-64.png"  res/64x64.png
cp -v "$BD/branding/logo-512.png" res/mac-icon.png 2>/dev/null || true
# Flutter Windows runner icon
if [ -d flutter/windows/runner/resources ]; then
    cp -v "$BD/branding/icon.ico" flutter/windows/runner/resources/app_icon.ico
fi

echo "==> BonDesk patches: Cargo.toml metadata"
sed -i 's|^description = "RustDesk Remote Desktop"$|description = "BonDesk - zdalna pomoc Bonhaku"|' Cargo.toml
sed -i 's|^authors = \["rustdesk <info@rustdesk.com>"\]$|authors = ["Bonhaku <support@bonhaku.pl>"]|' Cargo.toml

echo "==> BonDesk patches: pubspec.yaml metadata"
sed -i 's|^description: Your Remote Desktop Software\.$|description: BonDesk - zdalna pomoc Bonhaku|' flutter/pubspec.yaml || true
sed -i 's|^description: Your Remote Desktop Software$|description: BonDesk - zdalna pomoc Bonhaku|' flutter/pubspec.yaml || true

echo "==> BonDesk patches: window title (Windows runner main.cpp)"
# Window title shown in taskbar
if [ -f flutter/windows/runner/main.cpp ]; then
    sed -i 's|L"RustDesk"|L"BonDesk"|g' flutter/windows/runner/main.cpp
fi

echo "==> Done. Summary of changes:"
git diff --stat --no-color 2>/dev/null || true
