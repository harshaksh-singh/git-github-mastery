# labs/ch04/m02-setups.inc - starting directory for Lab 2.3 (the .gitignore trap).
# Sourced by setup-02-3-gitignore-trap.sh and by lab-02-3-gitignore-trap.sh so that both
# start from exactly the same files. Call it right after sandbox_begin or lab_begin.

# A project directory that has files but no repository yet: the state in which the
# first "git add ." is usually typed.
m02_3_setup() {
  mkdir -p support-bot/src/__pycache__
  printf 'import os\n\nKEY = os.environ["LLM_API_KEY"]\n\ndef answer(question):\n    return "ok"\n' > support-bot/src/app.py
  printf 'compiled bytecode\n' > support-bot/src/__pycache__/app.cpython-314.pyc
  printf 'fastapi\nuvicorn\n' > support-bot/requirements.txt
  printf 'LLM_API_KEY=lab-secret-0001\n' > support-bot/.env
}
