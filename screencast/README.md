# Screencast Script
For recording your screen with `ffmpeg`.

There are two scripts: **macOS** and **Gnome + Xorg**.

## Install ffmpeg
```shell
brew install ffmpeg   # macOS
sudo pacman -S ffmpeg # Arch Linux
```

## Usage
`./screencast-mac.sh output-video-name-without-extension`

...`Ctrl+C` stops and saves to `~/Videos/`

- Uses `ffmpeg` with near-lossless h.264

## macOS
Allow the "Terminal" app to record:

**Settings → Privacy → (Screen Recording and Microphone)**


## Tips
- Chrome: Full Screen and Zoom 150%
- Good battery or wired mouse and good mouse pad
- The username should be "**User**" (not your name).
- Pre-record one, then make the outline/script.
- Consider closing most of the panels.

### Mouse Movement
- Keep still at the end (about 5 seconds before Ctrl+C).
- Practice. It's ok to retry/redo when recording and cut in post.
- Avoid unnecessary movements
	- Don't shake/circle the mouse to indicate something (use the video editor).
	- Don't grab the mouse when not moving it.
	- Don't move away after an action, keep it there, until the next action.
	- Don't click needlessly (e.g. to deselect).
- Don't cover important text/icons with the cursor (e.g. in drop down menus).
- Pause before clicking.

### Editing
- Increase the video speed
- At the end, fade it to black
- When typing, cut the frames until there's only two between characters.

### Exporting
- crf = 28 (quality)
- encoder speed = slow


## Poster
Use `mpv` and hit `s` to save a screenshot.

These options are to save in the same video
directory. https://mpv.io/manual/master/#screenshot

**~/.config/mpv/mpv.conf**
```conf
screenshot-format="png"
screenshot-png-compression=0
screenshot-template=./%F
```


## License
This program is [ISC licensed](./LICENSE).
