#!/bin/sh

if [ `uname` = "Darwin" ]; then
  /usr/bin/osascript << EOF
tell application "Chrome" to tell the active tab of its first window
  reload
end tell
EOF

else
  PREV_APP=$(xdotool getwindowfocus)
  xdotool search --onlyvisible --class Chromium windowfocus key F5
  xdotool windowactivate $PREV_APP
fi

# TODO check if there's some Signal like SIGUSR to send to chrome/chorimum
# https://gist.github.com/lawrencejones/8906909

