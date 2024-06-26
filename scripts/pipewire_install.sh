#!/bin/bash
echo ""
read -p "   Pipewire Installer

   This script will replace Pulseaudio as the audio server with Pipewire.
   This is an EXPERIMENTAL usage of Pipewire. Use at your own risk.

   https://wiki.debian.org/PipeWire 
   
   During installation, You will probably want to choose 'no' when asked 
   to 'enable realtime process priority'. 
   
   After installation a Pnmixer error warning box SHOULD come up. Choose 
   'yes' to re-initialize the audio connection.  If this warning doesn't 
   appear, you may need to right-click on pnmixer and 'Reload Sound'.
   
   -------------------------------------------------
   
   Please press enter to install and use Pipewire.
   
   -------------------------------------------------
 
   Or close this terminal window to quit the install." ;
echo "" 
sudo apt update && sudo apt install pipewire pipewire-audio-client-libraries \
libspa-0.2-bluetooth libspa-0.2-jack qjackctl &&
sudo touch /etc/pipewire/media-session.d/with-pulseaudio &&
sudo touch /etc/pipewire/media-session.d/with-alsa &&
sudo touch /etc/pipewire/media-session.d/with-jack &&
sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.* /etc/systemd/user/ &&
sudo cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/ &&
sudo cp /usr/share/doc/pipewire/examples/ld.so.conf.d/pipewire-jack-*.conf /etc/ld.so.conf.d/ &&
systemctl --user daemon-reload &&
systemctl --user --now disable pulseaudio.service pulseaudio.socket &&
systemctl --user --now enable pipewire pipewire-pulse &&
systemctl --user mask pulseaudio &&
sleep 1
sudo ldconfig
echo ""
echo ""
echo "-----------------------------------------------------"
echo ""
LANG=C pactl info | grep '^Server Name'
echo ""
echo "-----------------------------------------------------"
echo ""
echo "If Pipewire is correctly set up, you should see above:"
echo ""
echo "'Server Name: PulseAudio (on PipeWire 0.3.XX)'"
echo ""
echo ""
echo "Remember if no Pnmixer warning box appeared, right-click" 
echo "on Pnmixer (sound icon) and 'Reload Sound'."
echo ""
echo "All Finished!"
echo ""
echo ""
echo "-----------------------------------------------------"
