#!/usr/bin/env bash
set -euo pipefail

VIDEO_MODE=false

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--video) VIDEO_MODE=true; shift ;;
    -h|--help)
      echo "Usage: $0 [-v] <channel-url> [output-directory]"
      echo "  -v, --video    Download as video (skip audio conversion)"
      echo "Example: $0 https://www.youtube.com/@8sistema audio"
      echo "Example: $0 -v https://www.youtube.com/@8sistema videos"
      exit 0 ;;
    *) break ;;
  esac
done

if [ $# -lt 1 ]; then
  echo "Usage: $0 [-v] <channel-url> [output-directory]"
  exit 1
fi

if ! command -v yt-dlp &>/dev/null; then
  echo "yt-dlp not found. Installing..."
  pip3 install --break-system-packages --user yt-dlp
fi

if [ "$VIDEO_MODE" = false ]; then
  if ! command -v ffmpeg &>/dev/null; then
    echo "ffmpeg not found. Installing via imageio-ffmpeg..."
    pip3 install --break-system-packages --user imageio-ffmpeg
  fi
fi

export PATH="$HOME/.local/bin:$PATH"

CHANNEL_URL="$1"
OUTPUT_DIR="${2:-downloads}"
mkdir -p "$OUTPUT_DIR"

FFMPEG_PATH=""
if command -v ffmpeg &>/dev/null; then
  FFMPEG_PATH=$(command -v ffmpeg)
elif python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())" &>/dev/null; then
  FFMPEG_PATH=$(python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())")
fi

YT_DLP=$(command -v yt-dlp)

if [ "$VIDEO_MODE" = true ]; then
  "$YT_DLP" \
    $( [ -n "$FFMPEG_PATH" ] && echo "--ffmpeg-location $FFMPEG_PATH" ) \
    -f "bestvideo+bestaudio/best" \
    --merge-output-format mp4 \
    -o "$OUTPUT_DIR/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" \
    --ignore-errors \
    --no-overwrites \
    --continue \
    --embed-thumbnail \
    --add-metadata \
    --yes-playlist \
    "$CHANNEL_URL"
else
  if [ -z "$FFMPEG_PATH" ]; then
    echo "Error: ffmpeg not found. Cannot convert to audio."
    exit 1
  fi
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
fi

echo "Done! Files saved to: $OUTPUT_DIR"
