# Incident 7: what was reported

**Project:** `eval-reports`. **Sandbox:** `server.git` (the server) and `you/` (your clone). **Evidence on paper:** [`evidence/ci.yml`](evidence/ci.yml) (the workflow file, also in the repository as `.github/workflows/ci.yml`) and [`evidence/RUN-REPORT.md`](evidence/RUN-REPORT.md) (what each step of the failed run reported).

> GitHub Actions cannot be run from this course. The run report is constructed for the exercise and says so. You diagnose from the workflow file, the report and the repository, and you use plain Git wherever Git can reproduce what the runner did.

Asha, in the channel:

> CI is red on my pull request and I have changed one docstring. Everything passes on my Mac: the version script prints a version and the tests are green. On GitHub the "Compute version" step dies with exit code 128. I re-ran it twice. It must be a flaky runner or an outage on their side, the tag it needs is right there on the tags page. Can someone with admin rights merge it anyway? It is only a docstring.

Ravi:

> `main` has been red since last week as well, so it is not your pull request. I assumed it would sort itself out.

What you are asked for: explain why the step fails on the runner and not on a laptop, fix the cause in the repository, and check whether the job would be green afterwards or whether a second failure is waiting behind the first. Push your fix as the branch `fix/ci-checkout`. Answer the request to "merge it anyway".

When you think you are done, run `incidents/07-ci-passes-locally/check.sh` from the course root. The check reads the files on `fix/ci-checkout` on the server. It cannot run the workflow.
