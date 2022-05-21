#!/bin/sh

# ./screencast.sh video_name_without_extension
#   - It countdowns 5 seconds and plays a sound when ready
#   - Hit Ctrl+C to "End and Save"

VNAME=$1
OUTDIR=~/Videos
PORT=`xrandr | awk '/ connected/{ print $1 }'` # Assumes only one monitor is connected
FPS=30
RES=2560x1440 # WQHD

mkdir -p $OUTDIR
vidname="${OUTDIR}/${VNAME}-$(date).mkv"

# Ensure the display resolution is 2.5K
xrandr --output $PORT --mode $RES

# Ensures scaling is at 200%. This isn't perfect https://wiki.archlinux.org/index.php/HiDPI
gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "[{'Gdk/WindowScalingFactor', <2>}]"
gsettings set org.gnome.desktop.interface scaling-factor 2

# Delay
COUNTDOWN_SEC=5
while [ $COUNTDOWN_SEC -gt 0 ]; do
  printf "\rRecording in %d..." $COUNTDOWN_SEC
  sleep 1
  COUNTDOWN_SEC=$((COUNTDOWN_SEC - 1))
done
paplay /usr/share/sounds/gnome/default/alerts/drip.ogg

# Full-Screen Recording https://trac.ffmpeg.org/wiki/Capture/Desktop
# No Audio (-an)
# Lossless (-crf 0) 
ffmpeg \
  -an \
  -video_size $RES \
  -framerate $FPS \
  -f x11grab \
  -i :0.0 -c:v libx264 -crf 0 \
  -preset ultrafast \
  "$vidname"

