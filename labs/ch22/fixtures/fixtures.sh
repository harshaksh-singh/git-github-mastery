#!/usr/bin/env bash
# labs/ch22/fixtures/fixtures.sh
# Hidden setup shared by the Chapter 22 demos, the Module 15 lab replays (15.3 and 15.4) and their
# hands-on setup scripts. Source it after lab-env.sh:   . "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
# Every fx_* function expects the current directory to be the sandbox ($LAB_DIR) and leaves you
# inside your clone, transcriber, unless its comment says otherwise.
#
# The project is "transcriber", a speech-to-text service. Its code is small; its model file is not.
#   remotes/transcriber.git   the shared repository (a bare repository reached through a file path)
#   transcriber/              your clone
#
# Git LFS is installed per repository with "git lfs install --local". Nothing here touches the
# global or system Git configuration. Because the lab's global configuration has no LFS filter, a
# plain "git clone" in the sandbox behaves like a clone on a machine without the LFS client.

FX22_DIR="$LAB_SCRIPT_DIR/fixtures"

put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }
commit_all() { tick; git add -A > /dev/null 2>&1 && git commit -q -m "$1" > /dev/null 2>&1; }

# weights <path> <seed> <bytes>: a deterministic, incompressible stand-in for a model file.
weights() { python3 "$FX22_DIR/make-weights.py" "$1" "$2" "$3"; }

handson_ready() {
  printf 'Lab sandbox ready: %s\n' "$LAB_DIR"
  printf 'Open the lab shell there and enter the repository:\n'
  printf '    labs/shell %s\n' "$LAB_DEMO"
  printf '    cd %s\n' "$1"
  return 0
}

_code() {
  put transcribe.py <<'PY'
import sys

MODEL = "models/acoustic.onnx"


def transcribe(path):
    session = load(MODEL)
    return session.run(read_audio(path))


if __name__ == "__main__":
    print(transcribe(sys.argv[1]))
PY
  put models/vocab.txt <<'TXT'
<blank>
a
b
c
TXT
  put README.md <<'MD'
# transcriber

Speech to text. The acoustic model lives in models/.
MD
}

# fx_transcriber_code: remotes/transcriber.git and your clone with one commit of code, pushed.
fx_transcriber_code() {
  mkdir -p remotes
  quiet 'git init --bare remotes/transcriber.git'
  quiet 'git clone remotes/transcriber.git transcriber'
  cd transcriber || return 1
  _code
  commit_all 'Add transcription entry point'
  quiet 'git push -u origin main'
}

# fx_transcriber_plain: the mistake. Three versions of the model committed as ordinary blobs, nothing
# pushed after the first commit. Sizes: 1,200,000 then 1,250,000 then 1,300,000 bytes.
fx_transcriber_plain() {
  fx_transcriber_code
  weights models/acoustic.onnx acoustic-v1 1200000
  commit_all 'Add acoustic model v1'
  weights models/acoustic.onnx acoustic-v2 1250000
  commit_all 'Retrain acoustic model on noisy audio (v2)'
  put transcribe.py <<'PY'
import sys

MODEL = "models/acoustic.onnx"
SAMPLE_RATE = 16000


def transcribe(path):
    session = load(MODEL)
    return session.run(read_audio(path, SAMPLE_RATE))


if __name__ == "__main__":
    print(transcribe(sys.argv[1]))
PY
  commit_all 'Resample input to 16 kHz'
  weights models/acoustic.onnx acoustic-v3 1300000
  commit_all 'Retrain acoustic model with accents (v3)'
}

# fx_transcriber_lfs: the model tracked with LFS from the start. LFS installed locally, *.onnx
# tracked, model v1 committed and pushed (pointer to Git, object to the LFS store of the remote).
fx_transcriber_lfs() {
  fx_transcriber_code
  quiet 'git lfs install --local'
  quiet 'git lfs track "*.onnx"'
  commit_all 'Track ONNX models with Git LFS'
  weights models/acoustic.onnx acoustic-v1 1200000
  commit_all 'Add acoustic model v1'
  quiet 'git push origin main'
}

# fx_transcriber_lfs_v2: fx_transcriber_lfs plus a second model version, committed and pushed.
fx_transcriber_lfs_v2() {
  fx_transcriber_lfs
  weights models/acoustic.onnx acoustic-v2 1250000
  commit_all 'Retrain acoustic model on noisy audio (v2)'
  quiet 'git push origin main'
}

# fx_transcriber_new_model: fx_transcriber_code plus two new binary files in the working tree,
# not yet added: the acoustic model (1,200,000 bytes) and a sample recording (48,000 bytes).
# This is the starting point of Lab 15.3.
fx_transcriber_new_model() {
  fx_transcriber_code
  weights models/acoustic.onnx acoustic-v1 1200000
  weights samples/hello.wav hello 48000
}

# fx_transcriber_plain_branch: fx_transcriber_plain plus a second unpushed branch,
# experiment/quantized, that starts at the v2 commit and adds a quantized model (600,000 bytes).
# You end on main. This is the starting point of Lab 15.4.
fx_transcriber_plain_branch() {
  fx_transcriber_plain
  quiet 'git switch -c experiment/quantized HEAD~2'
  weights models/acoustic-int8.onnx acoustic-int8 600000
  commit_all 'Add 8-bit quantized acoustic model'
  quiet 'git switch main'
}

# fx_transcriber_lab153_done: the end state of the main path of Lab 15.3, built quietly: LFS
# installed locally, *.onnx and *.wav tracked, both binaries committed as pointers, nothing pushed.
fx_transcriber_lab153_done() {
  fx_transcriber_new_model
  quiet 'git lfs install --local'
  quiet 'git lfs track "*.onnx" "*.wav"'
  commit_all 'Add acoustic model and sample recording, tracked with Git LFS'
}

# fx_transcriber_lab154_done: the end state of Lab 15.4, built quietly: the unpushed commits of both
# branches migrated, the pushed commit untouched.
fx_transcriber_lab154_done() {
  fx_transcriber_plain_branch
  quiet 'git lfs install --local'
  quiet 'git lfs migrate import --include="*.onnx" --yes main experiment/quantized'
  quiet 'git lfs checkout'
}
