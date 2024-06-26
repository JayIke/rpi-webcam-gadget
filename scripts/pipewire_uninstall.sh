#!/bin/bash
echo ""
echo ""
read -p "   Pipewire Remover

   If you are using Pipewire, and want to switch back to Pulseaudio.

   After installation a Pnmixer error warning box SHOULD come up. Choose 
   'yes' to re-initialize the audio connection.  If this warning doesn't 
   appear, you may need to right-click on pnmixer and 'Reload Sound'.  

   -------------------------------------------------
   
   Please press enter to Switch back to Pulseaudio.
   
   -------------------------------------------------
   
   
   Or close this terminal window to quit." ;
echo "" 
sudo apt remove pipewire-audio-client-libraries \
libspa-0.2-bluetooth libspa-0.2-jack qjackctl &&
sudo rm /etc/systemd/user/pipewire-pulse.* &&
sudo rm /etc/alsa/conf.d/99-pipewire-default.conf &&
sudo rm /etc/ld.so.conf.d/pipewire-jack-*.conf &&
systemctl --user daemon-reload &&
systemctl --user --now disable pipewire pipewire-pulse &&
systemctl --user unmask pulseaudio &&
systemctl --user --now enable pulseaudio.service pulseaudio.socket &&
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
echo "If Pipewire has been sucessfully removed, you should see:"
echo "'Server Name: PulseAudio'" above.
echo ""
echo "Remember if no Pnmixer warning box appeared, right-click" 
echo "on Pnmixer (sound icon) and 'Reload Sound'."
echo ""
echo "All Finished!"
echo ""
echo ""
echo "-----------------------------------------------------"
