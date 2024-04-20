#!bin/bash

# Sanity check pipewire services and sockets

# Check for new service files:
systemctl --user daemon-reload

# Disable PulseAudio
systemctl --user --now disable pulseaudio.service pulseaudio.socket

# Enable and start the pipewire-pulse service
systemctl --user --now enable pipewire pipewire-pulse


