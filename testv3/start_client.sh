#!/usr/bin/env bash
set -euo pipefail

SERVER_URL="${SERVER_URL:-https://clbkynangpct-langnang--openslt-realtime-realtime-app.modal.run}"
PYTHON_EXE="${PYTHON_EXE:-python3}"
CAMERA_INDEX="${CAMERA_INDEX:-0}"
CAMERA_FPS="${CAMERA_FPS:-30}"
CAMERA_WARMUP_SECONDS="${CAMERA_WARMUP_SECONDS:-1.2}"
SAMPLE_FPS="${SAMPLE_FPS:-15}"
CHUNK_FRAMES="${CHUNK_FRAMES:-10}"   # latency opt (was 15; to revert: change 10 -> 15 here)
FRAME_WIDTH="${FRAME_WIDTH:-640}"
FRAME_HEIGHT="${FRAME_HEIGHT:-480}"
JPEG_QUALITY="${JPEG_QUALITY:-72}"
UPLOAD_WORKERS="${UPLOAD_WORKERS:-3}"
MAX_PENDING_UPLOADS="${MAX_PENDING_UPLOADS:-6}"
CHUNK_ENDPOINT="${CHUNK_ENDPOINT:-/api/chunk_early}"
REQUEST_TIMEOUT="${REQUEST_TIMEOUT:-60}"
DURATION_SECONDS="${DURATION_SECONDS:-0}"
SHOW_PREVIEW="${SHOW_PREVIEW:-1}"
DEBUG_TIMING="${DEBUG_TIMING:-1}"
SERVER_STATS_INTERVAL="${SERVER_STATS_INTERVAL:-1}"
SPEAK="${SPEAK:-1}"
SPEECH_MODE="${SPEECH_MODE:-final}"
SPEECH_BACKEND="${SPEECH_BACKEND:-auto}"
SPEECH_APLAY_DEVICE="${SPEECH_APLAY_DEVICE:-${AUDIO_DEVICE:-}}"
SPEECH_VOICE="${SPEECH_VOICE:-}"
SPEECH_RATE="${SPEECH_RATE:-175}"
SPEECH_COMMAND_TIMEOUT="${SPEECH_COMMAND_TIMEOUT:-20}"
SPEECH_DEBUG="${SPEECH_DEBUG:-1}"
SPEECH_TEST_TEXT="${SPEECH_TEST_TEXT:-}"
AUDIO_CUES="${AUDIO_CUES:-1}"
AUDIO_CUE_BACKEND="${AUDIO_CUE_BACKEND:-auto}"
AUDIO_CUE_DEVICE="${AUDIO_CUE_DEVICE:-${AUDIO_DEVICE:-}}"
AUDIO_CUE_VOLUME="${AUDIO_CUE_VOLUME:-0.35}"
AUDIO_CUE_DEBUG="${AUDIO_CUE_DEBUG:-0}"
AUDIO_HIGH_LATENCY_MS="${AUDIO_HIGH_LATENCY_MS:-6000}"
AUDIO_HIGH_LATENCY_INTERVAL_SECONDS="${AUDIO_HIGH_LATENCY_INTERVAL_SECONDS:-12}"
AUDIO_UTTERANCE_STARTED_CUE="${AUDIO_UTTERANCE_STARTED_CUE:-0}"
CLIENT_LOG_FILE="${CLIENT_LOG_FILE:-}"
KEEP_TERMINAL_OPEN="${KEEP_TERMINAL_OPEN:-0}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "Checking Python..."
"$PYTHON_EXE" --version

echo "Checking client dependencies..."
MISSING_PKGS="$("$PYTHON_EXE" - <<'PY'
import importlib.util
required = ["cv2", "numpy", "requests"]
missing = [name for name in required if importlib.util.find_spec(name) is None]
print(" ".join(missing))
PY
)"

if [[ -n "$MISSING_PKGS" ]]; then
  echo "Installing missing packages: $MISSING_PKGS"
  "$PYTHON_EXE" -m pip install numpy requests opencv-python
else
  echo "All required packages are already installed."
fi

PREVIEW_ARG="--show-preview"
if [[ "$SHOW_PREVIEW" == "0" ]]; then
  PREVIEW_ARG="--no-show-preview"
fi

DEBUG_TIMING_ARG="--debug-timing"
if [[ "$DEBUG_TIMING" == "0" ]]; then
  DEBUG_TIMING_ARG="--no-debug-timing"
fi

SPEAK_ARG="--speak"
if [[ "$SPEAK" == "0" ]]; then
  SPEAK_ARG="--no-speak"
fi

AUDIO_CUES_ARG="--audio-cues"
if [[ "$AUDIO_CUES" == "0" ]]; then
  AUDIO_CUES_ARG="--no-audio-cues"
fi

SPEECH_VOICE_ARGS=()
if [[ -n "$SPEECH_VOICE" ]]; then
  SPEECH_VOICE_ARGS=(--speech-voice "$SPEECH_VOICE")
fi

SPEECH_DEBUG_ARG="--speech-debug"
if [[ "$SPEECH_DEBUG" == "0" ]]; then
  SPEECH_DEBUG_ARG="--no-speech-debug"
fi

AUDIO_CUE_DEBUG_ARG="--no-audio-cue-debug"
if [[ "$AUDIO_CUE_DEBUG" != "0" ]]; then
  AUDIO_CUE_DEBUG_ARG="--audio-cue-debug"
fi

AUDIO_UTTERANCE_STARTED_ARG="--no-audio-utterance-started-cue"
if [[ "$AUDIO_UTTERANCE_STARTED_CUE" != "0" ]]; then
  AUDIO_UTTERANCE_STARTED_ARG="--audio-utterance-started-cue"
fi

SPEECH_TEST_ARGS=()
if [[ -n "$SPEECH_TEST_TEXT" ]]; then
  SPEECH_TEST_ARGS=(--speech-test-text "$SPEECH_TEST_TEXT")
fi

echo
echo "Starting Raspberry Pi client..."
echo "Server URL : $SERVER_URL"
echo "Camera idx : $CAMERA_INDEX"
echo "Cam warmup : ${CAMERA_WARMUP_SECONDS}s"
echo "Preview    : $SHOW_PREVIEW"
echo "Timeout    : $REQUEST_TIMEOUT"
echo "Duration   : $DURATION_SECONDS"
echo "Debug      : $DEBUG_TIMING"
echo "Srv stats  : $SERVER_STATS_INTERVAL"
echo "Sample FPS : $SAMPLE_FPS"
echo "Chunk frames: $CHUNK_FRAMES"
echo "Resolution : ${FRAME_WIDTH}x${FRAME_HEIGHT}"
echo "JPEG quality: $JPEG_QUALITY"
echo "Workers    : $UPLOAD_WORKERS"
echo "Max pending: $MAX_PENDING_UPLOADS"
echo "Chunk API  : $CHUNK_ENDPOINT"
echo "Speak      : $SPEAK"
echo "Speech mode: $SPEECH_MODE"
echo "Speech back: $SPEECH_BACKEND"
echo "Speech dev : ${SPEECH_APLAY_DEVICE:-default}"
echo "Speech rate: $SPEECH_RATE"
echo "Speech to  : ${SPEECH_COMMAND_TIMEOUT}s"
echo "Speech dbg : $SPEECH_DEBUG"
echo "Audio cues : $AUDIO_CUES"
echo "Audio back : $AUDIO_CUE_BACKEND"
echo "Audio dev  : ${AUDIO_CUE_DEVICE:-default}"
echo "Audio lat  : ${AUDIO_HIGH_LATENCY_MS}ms / ${AUDIO_HIGH_LATENCY_INTERVAL_SECONDS}s"
echo "Keep open  : $KEEP_TERMINAL_OPEN"
if [[ -n "$CLIENT_LOG_FILE" ]]; then
  echo "Log file   : $CLIENT_LOG_FILE"
fi
if [[ -n "$SPEECH_TEST_TEXT" ]]; then
  echo "Speech test: $SPEECH_TEST_TEXT"
fi
echo "Flow       : browser_like async uploads"
echo

if [[ "$SPEAK" != "0" || "$AUDIO_CUES" != "0" ]]; then
  echo "Speech/audio diagnostics:"
  for cmd in espeak-ng espeak spd-say; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "  $cmd: $(command -v "$cmd")"
    else
      echo "  $cmd: not found"
    fi
  done
  if command -v aplay >/dev/null 2>&1; then
    aplay -l 2>&1 | sed 's/^/  aplay: /' || true
  else
    echo "  aplay: not found"
  fi
  if command -v pactl >/dev/null 2>&1; then
    pactl info 2>&1 | sed 's/^/  pactl: /' || true
  else
    echo "  pactl: not found"
  fi
  if [[ "$AUDIO_CUES" != "0" && "$AUDIO_CUE_BACKEND" == "auto" ]]; then
    echo "  note: if no aplay/paplay/pw-play/ffplay works, cues fall back to terminal bell, which is often silent."
    echo "  tip : install/test ALSA with: sudo apt install -y alsa-utils && speaker-test -t sine -f 880 -l 1"
  fi
  if [[ -z "$AUDIO_CUE_DEVICE" && -z "$SPEECH_APLAY_DEVICE" ]]; then
    echo "  tip : Raspberry Pi headphones often appear as ALSA card 2. Try: AUDIO_DEVICE=plughw:2,0 ./start_client.sh"
  else
    echo "  using ALSA devices: cue=${AUDIO_CUE_DEVICE:-default} speech=${SPEECH_APLAY_DEVICE:-default}"
  fi
  echo
fi

CLIENT_ARGS=(
  client.py
  --base-url "$SERVER_URL"
  --camera-index "$CAMERA_INDEX"
  --camera-fps "$CAMERA_FPS"
  --camera-warmup-seconds "$CAMERA_WARMUP_SECONDS"
  --sample-fps "$SAMPLE_FPS"
  --chunk-frames "$CHUNK_FRAMES"
  --width "$FRAME_WIDTH"
  --height "$FRAME_HEIGHT"
  --jpeg-quality "$JPEG_QUALITY"
  --upload-workers "$UPLOAD_WORKERS"
  --max-pending-uploads "$MAX_PENDING_UPLOADS"
  --chunk-endpoint "$CHUNK_ENDPOINT"
  --request-timeout "$REQUEST_TIMEOUT"
  --duration-seconds "$DURATION_SECONDS"
  --server-stats-interval "$SERVER_STATS_INTERVAL"
  "$SPEAK_ARG"
  --speech-mode "$SPEECH_MODE"
  --speech-backend "$SPEECH_BACKEND"
  --speech-aplay-device "$SPEECH_APLAY_DEVICE"
  --speech-rate "$SPEECH_RATE"
  --speech-command-timeout "$SPEECH_COMMAND_TIMEOUT"
  "$AUDIO_CUES_ARG"
  --audio-cue-backend "$AUDIO_CUE_BACKEND"
  --audio-cue-device "$AUDIO_CUE_DEVICE"
  --audio-cue-volume "$AUDIO_CUE_VOLUME"
  --audio-high-latency-ms "$AUDIO_HIGH_LATENCY_MS"
  --audio-high-latency-interval-seconds "$AUDIO_HIGH_LATENCY_INTERVAL_SECONDS"
  "$AUDIO_CUE_DEBUG_ARG"
  "$AUDIO_UTTERANCE_STARTED_ARG"
  "${SPEECH_VOICE_ARGS[@]}"
  "${SPEECH_TEST_ARGS[@]}"
  "$SPEECH_DEBUG_ARG"
  "$DEBUG_TIMING_ARG"
  "$PREVIEW_ARG"
)

set +e
if [[ -n "$CLIENT_LOG_FILE" ]]; then
  "$PYTHON_EXE" "${CLIENT_ARGS[@]}" 2>&1 | tee "$CLIENT_LOG_FILE"
  CLIENT_RC=${PIPESTATUS[0]}
else
  "$PYTHON_EXE" "${CLIENT_ARGS[@]}"
  CLIENT_RC=$?
fi
set -e

echo
echo "[client] exited rc=$CLIENT_RC"
if [[ "$KEEP_TERMINAL_OPEN" != "0" ]]; then
  read -r -p "Press Enter to close..." _
fi
exit "$CLIENT_RC"
