# ~/.bash_aliases
#
# Enable a bash alias file:
# 1) place this file in ~/.bash_aliases
# 2) cd ~
# 3) source ~/.bashrc
#
# Example: device-map
# Outputs: prints paths, id nodes, and links of sound v4l and video devices (pipeline related)
#
# RPI Z2W AI Webcam Project
# AI, Video and Audio

# Show camera devices v4l recognizes
alias show-video='v4l2-ctl --list-devices'

# Show audio capture and playback soundcards
alias show-audio='arecord -l && aplay -l'

# Start audio capture 2-channel,48kHz sample rate, signed 32-bit little endian format, save to wave
alias capture-audio='arecord -D plughw:0,0 -c 2 -r 48000 -f s32_le -t wav cap_audio.wav'

# show system devices
alias show-units='systemctl list-units'

# search for relevant modules
alias show-modules='lsmod | grep -iE "snd|g_|usb|uvc|vid|audio|sound|i2s|gadget|camera|lib"'

# show size and classifcation of files in directory - column
alias lt='ls --human-readable --size -1 -S --classify'

# shows device path, link, id node, and
alias device-map='ls -R -L -i -c /dev/snd/ /dev/v4l/ /dev/bus /dev/video*'
