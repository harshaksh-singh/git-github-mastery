# The README paragraph was cherry-picked to main. Both tips have it, the merge base does not.
$ git diff --stat main feat/report -- README.md
$ git diff main...feat/report -- README.md
diff --git a/README.md b/README.md
index bfae817..08f9933 100644
--- a/README.md
+++ b/README.md
@@ -5,3 +5,5 @@ Scores model answers against reference answers.
     python3 -m scorekit.runner data/smoke.jsonl
 
 The runner prints one score line and exits with status 1 when exact_match is below the pass mark.
+
+The nightly job runs the same command on data/nightly.jsonl.
