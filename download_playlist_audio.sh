#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <playlist-url> [output-directory]"
  echo "Example: $0 https://www.youtube.com/playlist?list=PL... music"
  exit 1
fi

if ! command -v yt-dlp &>/dev/null; then
  echo "yt-dlp not found. Installing..."
  pip3 install --break-system-packages --user yt-dlp
fi

if ! command -v ffmpeg &>/dev/null; then
  echo "ffmpeg not found. Installing via imageio-ffmpeg..."
  pip3 install --break-system-packages --user imageio-ffmpeg
fi

export PATH="$HOME/.local/bin:$PATH"

PLAYLIST_URL="$1"
OUTPUT_DIR="${2:-playlist_audio}"
mkdir -p "$OUTPUT_DIR"

FFMPEG_PATH=""
if command -v ffmpeg &>/dev/null; then
  FFMPEG_PATH=$(command -v ffmpeg)
elif python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())" &>/dev/null; then
  FFMPEG_PATH=$(python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())")
fi

YT_DLP=$(command -v yt-dlp)

"$YT_DLP" \
  --ffmpeg-location "$FFMPEG_PATH" \
  -f bestaudio \
  --extract-audio \
  --audio-format mp3 \
  --audio-quality 0 \
  -o "$OUTPUT_DIR/%(playlist_index)02d - %(title)s.%(ext)s" \
  --ignore-errors \
  --no-overwrites \
  --continue \
  --embed-thumbnail \
  --add-metadata \
  --yes-playlist \
  --no-playlist-reverse \
  "$PLAYLIST_URL"

echo "Done! Files saved to: $OUTPUT_DIR"
