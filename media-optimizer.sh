#!/bin/sh
set -o noglob
IFS=$'\n'

# https://blog.uxtely.com/convert-to-avif-programmatically

# Requires:
# brew install oxipng webp libavif ffmpeg

# We only use PNGs, no JPGs. This way we can ensure
# there's no color shifting and PNGs look sharper anyways.
nJPG=$(find $1 -type f -name *.jpg | awk 'END{print NR}')
if [ $nJPG != 0 ]; then
  echo "ERROR: Found a JPG. Convert it to PNG" >&2
  exit 1
fi

# If there's no foo.png.avif, foo.png outputs:
#  1. foo.png (better compressed lossless, and without EXIF metadata)
#  2. foo.png.avif
#  3. foo.png.webp
for img in $(find $1 -type f -name *.png); do
  if [ ! -f "$img.avif" ]; then
    chmod 644 $img
    oxipng --opt max --strip safe $img
    cwebp $img -o "$img.webp"
    avifenc --speed 0 --min 25 --max 35 $img "$img.avif"
  fi
done


# For faster video playback, the metadata section (moov) of an mp4
# should appear before the video and audio section (mdat).
# https://trac.ffmpeg.org/wiki/HowToCheckIfFaststartIsEnabledForPlayback
# https://www.ramugedia.com/mp4-container
for video in $(find $1 -type f -name *.mp4); do
  mp4_section_appearing_first=`ffmpeg -v trace -i $video NUL 2>&1 | grep --max-count 1 --only-matching -e "type:'mdat'" -e "type:'moov'"`
  if [ $mp4_section_appearing_first != "type:'moov'" ]; then
    ffmpeg -i $video -movflags +faststart $video.tmp.mp4
    rm $video
    mv $video.tmp.mp4 $video
  fi
done

