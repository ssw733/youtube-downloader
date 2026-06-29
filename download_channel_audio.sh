#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <channel-url> [output-directory]"
  echo "Example: $0 https://www.youtube.com/@8sistema audio"
  exit 1
fi

# Install dependencies if missing
if ! command -v yt-dlp &>/dev/null; then
  echo "yt-dlp not found. Installing..."
  pip3 install --break-system-packages --user yt-dlp
fi

if ! command -v ffmpeg &>/dev/null; then
  echo "ffmpeg not found. Installing via imageio-ffmpeg..."
  pip3 install --break-system-packages --user imageio-ffmpeg
fi

# Ensure local bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

CHANNEL_URL="$1"
OUTPUT_DIR="${2:-downloads}"
mkdir -p "$OUTPUT_DIR"

# Try to find ffmpeg, use it if available
FFMPEG_PATH=""
if command -v ffmpeg &>/dev/null; then
  FFMPEG_PATH=$(command -v ffmpeg)
elif python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())" &>/dev/null; then
  FFMPEG_PATH=$(python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())")
fi

YT_DLP=$(command -v yt-dlp)

if [ -n "$FFMPEG_PATH" ]; then
  "$YT_DLP" \
    --ffmpeg-location "$FFMPEG_PATH" \
    -f bestaudio \
    --extract-audio \
    --audio-format mp3 \
    --audio-quality 0 \
    -o "$OUTPUT_DIR/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" \
    --ignore-errors \
    --no-overwrites \
    --continue \
    --embed-thumbnail \
    --add-metadata \
    --yes-playlist \
    "$CHANNEL_URL"
else
  echo "Error: ffmpeg not found. Cannot convert to audio."
  exit 1
fi

echo "Done! Files saved to: $OUTPUT_DIR"
