#!/bin/sh

# ./screencast.sh video_name_without_extension
#   Hit Ctrl+C to "End and Save"

VNAME=$1
OUTDIR=~/Videos

mkdir -p $OUTDIR
vidname="${OUTDIR}/${VNAME}-screencast-$(date)"

# Picks the "Main" screen (the one with the top menubar in the Display Preferences)
SCREEN_NUM=`ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "Capture screen 0" | sed -e 's/.*\[\(.*\)\].*/\1/'`
INPUT="${SCREEN_NUM}:" # Screen:Microphone

# https://trac.ffmpeg.org/wiki/Capture/Desktop
# -crf 17 is not lossless but is very high quality (-crf 0 is lossless)
 ffmpeg -f avfoundation \
  -capture_cursor 1 \
  -i "$INPUT" -c:v libx264 -crf 17 \
  -preset ultrafast \
  "${vidname}.mkv"

# Convert mkv to mp4 because ffmpeg can't save to mp4 while
# screen-recording, and Final Cut Pro can't import mkv
ffmpeg -i "${vidname}.mkv" -c:v copy "${vidname}.mp4"

rm "${vidname}".mkv
