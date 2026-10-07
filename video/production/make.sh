#!/bin/bash
# One command for the whole video pipeline.  Run it from anywhere:
#
#   video/production/make.sh storyboard V008|all     script -> storyboard (beats and slides)
#   video/production/make.sh slides     V008|all     storyboard -> slide pictures
#   video/production/make.sh animate    V008|all     add the animation layer: typing terminals, reveals, explainer scenes, the mascot
#   video/production/make.sh animate    --off V008   remove it again (the video is built from still slides as before)
#   video/production/make.sh record     V008         open the recording booth in Google Chrome
#   video/production/make.sh build      V008|all     recording -> finished MP4, subtitles, chapters
#   video/production/make.sh draft      V008|all     preview MP4 with the computer voice (no recording needed)
#   video/production/make.sh status                  table of what exists for every video
#   video/production/make.sh selftest                check the booth and the builder without a microphone
#   video/production/make.sh demo                    a short video that plays every scene of the animation library
#   video/production/make.sh qc         V008|all     measure a finished video against QC_CHECKLIST.md (reads only; report in out/qc/)
#
# "all" skips what is already up to date.  Several videos or a range also work:  slides V008 V009   draft V010-V020
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
TOOLS="$ROOT/tools"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
PY="$(command -v python3 || true)"
if [ -z "$PY" ]; then echo "python3 was not found. Install the Xcode command line tools: xcode-select --install"; exit 1; fi

cmd="${1:-help}"
[ $# -gt 0 ] && shift

need_arg() {
  if [ $# -eq 0 ]; then echo "Say which video, for example: video/production/make.sh $cmd V008   (or: all)"; exit 2; fi
}

case "$cmd" in
  storyboard)
    need_arg "$@"; exec "$PY" "$TOOLS/video_storyboard.py" "$@" ;;
  slides)
    need_arg "$@"
    "$PY" "$TOOLS/video_storyboard.py" "$@" > /dev/null || true      # slides always follow the current script
    exec "$PY" "$TOOLS/video_slides.py" "$@" ;;
  animate)  # build, draft and voice use the animation of a video whenever it exists
    need_arg "$@"; exec "$PY" "$TOOLS/video_animate.py" "$@" ;;
  demo)     # every explainer scene, in a sandbox of its own: nothing of the course is touched
    export VIDEO_WORK_DIR="$HERE/.cache/demo" VIDEO_SCRIPTS_DIR="$TOOLS/anim/demo" VIDEO_OUT_DIR="$HERE/out/demo" VIDEO_NARRATOR=ai
    "$PY" "$TOOLS/video_storyboard.py" V000 && "$PY" "$TOOLS/video_slides.py" V000 > /dev/null && "$PY" "$TOOLS/video_animate.py" V000 || exit 1
    exec "$PY" "$TOOLS/video_build.py" --draft --voice "${NARRATOR_VOICE:-Tara}" --rate "${NARRATOR_RATE:-165}" V000 ;;
  record)
    need_arg "$@"; exec "$PY" "$TOOLS/video_booth.py" "$@" ;;
  build)
    need_arg "$@"; exec "$PY" "$TOOLS/video_build.py" "$@" ;;
  draft)
    need_arg "$@"; exec "$PY" "$TOOLS/video_build.py" --draft "$@" ;;
  voice)   # finished videos narrated by a computer voice: no stamp, named VNNN.mp4
    need_arg "$@"; VIDEO_NARRATOR=ai exec "$PY" "$TOOLS/video_build.py" --draft --voice "${NARRATOR_VOICE:-Tara}" --rate "${NARRATOR_RATE:-165}" "$@" ;;
  status)
    exec "$PY" "$TOOLS/video_status.py" "$@" ;;
  selftest)
    exec "$PY" "$TOOLS/video_selftest.py" "$@" ;;
  qc)       # quality control of finished videos: measures, never builds or re-encodes; --selftest needs no video
    need_arg "$@"; exec "$PY" "$TOOLS/video_qc.py" "$@" ;;
  help|-h|--help|*)
    sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    [ "$cmd" = help ] || [ "$cmd" = -h ] || [ "$cmd" = --help ] || { echo; echo "unknown command: $cmd"; exit 2; } ;;
esac
