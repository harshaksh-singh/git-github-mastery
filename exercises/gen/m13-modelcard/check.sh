#!/usr/bin/env bash
# Read-only verification of exercise 13.9. Exit status 0 means done.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m13-modelcard you/.git "${1:-}"
S=server.git
rel=$(id_of you main 'Put a blank line under the metrics heading')
fix=$(id_of you main 'Say so when a card has no metrics')
same 'v1.4.0 on the server is an annotated tag again' "$(git -C $S cat-file -t refs/tags/v1.4.0 2>/dev/null)" tag
same '  it names the commit that was released on Monday' "$(git -C $S rev-parse -q --verify 'refs/tags/v1.4.0^{commit}' 2>/dev/null)" "$rel"
same '  and it is the published object (tagger Asha Rao)' "$(git -C $S for-each-ref --format='%(taggername)' refs/tags/v1.4.0)" 'Asha Rao'
want=$(git -C $S rev-parse -q --verify refs/tags/v1.4.0 2>/dev/null)
same 'your clone has the same v1.4.0 object' "$(git -C you rev-parse -q --verify refs/tags/v1.4.0 2>/dev/null)" "$want"
same 'the build clone has the same v1.4.0 object' "$(git -C ci rev-parse -q --verify refs/tags/v1.4.0 2>/dev/null)" "$want"
same 'v1.4.1 on the server is an annotated tag' "$(git -C $S cat-file -t refs/tags/v1.4.1 2>/dev/null)" tag
same '  and it names the commit with the fix' "$(git -C $S rev-parse -q --verify 'refs/tags/v1.4.1^{commit}' 2>/dev/null)" "$fix"
same 'scripts/version.sh in ci/ prints v1.4.1' "$(cd ci && sh scripts/version.sh 2>/dev/null)" v1.4.1
same 'v1.3.0 was not touched' "$(git -C $S log -1 --format=%s v1.3.0 2>/dev/null)" 'Add Markdown renderer'
check_end
