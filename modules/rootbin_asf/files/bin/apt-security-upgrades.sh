#!/bin/sh
# -o APT::Get::Show-User-Simulation-Note=false 
# -o Dir::Etc::PreferencesParts
# apt_preferences(5)
# crontab: @daily apt-get update >/dev/null && $0 -s -qq upgrade

prefs=/root/bin/apt-security-upgrades.prefs
apt-get -o Dir::Etc::Preferences=$prefs "$@"
