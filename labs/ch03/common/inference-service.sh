# Shared builder for the Chapter 3 demos. Not a demo itself: source it after lab_begin.
#
#   . "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
#   build_inference_service
#
# It leaves the shell inside inference-service/, a small repository whose top-level tree uses
# all five entry modes and whose history has a second author, a merge and two tags:
#
#   *   M  Merge feature/batching            (main, tag v1.0.0, annotated)
#   |\
#   | * B  Add batch size setting            (feature/batching, by Asha)
#   * | R  Add readiness handler             (tag v1.0.0-rc1, lightweight)
#   |/
#   * S  Add inference service skeleton
#
# Every step goes through "quiet", so the clock ticks the same way in every demo that uses
# this builder and the object IDs are identical across those demos.
build_inference_service() {
  # A second repository stands in for a library that the service pins as a gitlink.
  quiet 'git init tokenizer-upstream'
  quiet "printf 'def tokenize(text):\n    return text.split()\n' > tokenizer-upstream/tokenizer.py"
  quiet 'git -C tokenizer-upstream add tokenizer.py'
  quiet 'git -C tokenizer-upstream commit -m "Add whitespace tokenizer"'

  quiet 'git init inference-service'
  cd inference-service || exit 1
  quiet 'mkdir -p src/handlers models tokenizer'
  quiet "printf 'retry_limit = 3\ntimeout_s = 30\n' > config.toml"
  quiet "printf '#!/bin/sh\nexec python3 -m src.server \"\$@\"\n' > run.sh && chmod +x run.sh"
  quiet "printf 'def predict(text):\n    return len(text)\n' > src/server.py"
  quiet "printf 'def health():\n    return \"ok\"\n' > src/handlers/health.py"
  quiet "printf 'weights-v2\n' > models/v2.bin"
  quiet 'ln -s models/v2.bin current-model'
  quiet 'git add .'
  # Register the library as a gitlink (mode 160000) without the submodule machinery of Chapter 23.
  quiet 'git update-index --add --cacheinfo 160000,$(git -C ../tokenizer-upstream rev-parse HEAD),tokenizer'
  quiet 'git commit -m "Add inference service skeleton"'

  quiet 'git switch -c feature/batching'
  as asha
  quiet "printf 'batch_size = 8\n' >> config.toml && git commit -am 'Add batch size setting'"
  as you
  quiet 'git switch main'
  quiet "printf 'def ready():\n    return True\n' > src/handlers/ready.py && git add . && git commit -m 'Add readiness handler'"
  quiet 'git tag v1.0.0-rc1'
  quiet "git merge --no-ff -m 'Merge feature/batching' feature/batching"
  quiet 'git tag -a v1.0.0 -m "Release 1.0.0"'
}
