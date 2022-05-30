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

