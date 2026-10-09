# Design of the YouTube publishing tool

`tools/youtube_publish.py` is one file with no dependency outside the Python standard library (`http.client`, `urllib`, `http.server`, `json`, `zoneinfo`). The owner's guide is [`README.md`](README.md).

## Architecture

```text
youtube-metadata.md  thumbnail-data.json  video-curriculum.md
QC-FINAL.md  qc/VNNN.qc.json  out/VNNN.chapters.txt  config.json (optional)
        |
      plan  ----->  plan.json (exactly what will be sent)  +  PLAN.md
        |
      check         offline rules + one HEAD per release asset on GitHub
        |
      auth          loopback OAuth with PKCE  ->  ~/.config/git-mastery-youtube/token.json
      whoami        channels.list(mine)       ->  confirmed channel in state.json
        |
      upload        per video: file -> insert (resumable) -> thumbnail -> captions
        |                      -> playlists -> verify;  state.json after every step
      verify        videos.list + playlistItems.list compared with plan.json -> VERIFY.md
      retime        videos.update(status) for changed publish times
      report        state.json + plan.json -> REPORT.md, report.csv (no API call)
```

Layers inside the file, each replaceable in the tests:

| Layer | Role |
|---|---|
| Readers and validators | Pure functions: parse the course files, check titles, descriptions (bytes), tags (YouTube's counting), chapters, captions, PNG header. |
| `build_plan` | Slot arithmetic in UTC from a start given in Asia/Kolkata; one item per video with its list of violations. Nothing is shortened. |
| `Http` | One request per connection through `http.client`; HTTPS only, plain HTTP only to loopback (the test server). No redirects are followed. |
| `Tokens` | Reads and refreshes the token; the only code that touches secrets. |
| `Ledger` | Quota count per Pacific-time day from the documented costs; `require` stops before a limit, `charge` records each attempt. |
| `Api` | The eleven API calls the tool uses, retry with exponential backoff, the resumable upload, and the dry-run printer. |
| `Uploader` | The per-video pipeline and the rules about what may be sent. |
| `FakeYouTube` + `selftest` | A local `http.server` that behaves like the API for those calls, including a dropped connection during an upload. |

The API surface is deliberately small: `channels.list`, `videoCategories.list`, `videos.insert`, `videos.list`, `videos.update` (status only, in `retime`), `thumbnails.set`, `captions.insert`, `playlists.list`, `playlists.insert`, `playlistItems.list`, `playlistItems.insert`. No delete method is called anywhere.

## State file

`video/youtube/state.json`, rewritten atomically (temporary file, `fsync`, rename) after every step:

```json
{
  "channel":   {"id": "UC...", "title": "...", "confirmed_at": "..."},
  "playlists": {"course": {"id": "PL...", "title": "..."}, "part-00": {"...": "..."}},
  "quota":     {"2026-10-20": {"units": 9367, "uploads": 17, "calls": {"captions.insert": 17}}},
  "videos":    {"V001": {"video_id": "...", "url": "https://youtu.be/...", "publish_at": "...",
                         "steps": {"insert": {"status": "ok", "at": "..."},
                                   "thumbnail": {"status": "ok"}, "captions": {"status": "ok"},
                                   "playlists": {"status": "ok", "items": {"course": {"status": "ok"}}},
                                   "verify": {"status": "ok"}},
                         "done": true, "errors": []}},
  "runs":      [{"started": "...", "finished": "...", "done": ["V001"], "stopped": null}]
}
```

A step is `pending`, `started`, `ok`, `failed` or (verify only) `processing`. `done` is true only when all five steps are `ok`. A rerun skips `done` videos and, for the others, repeats only the steps that are not `ok`.

`plan.json` is the single source of what is sent. `upload --reschedule` is the only command besides `plan` that rewrites it.

## Never upload twice

Three independent guards, checked in this order before any `videos.insert`:

1. **State.** A video with a `video_id` in `state.json` is never inserted again.
2. **Upload session.** The session address is stored (in `~/.config/git-mastery-youtube/sessions.json`) *before* the first byte is sent. A later run asks that session for its status first: finished sessions return the created video, unfinished ones are continued at the byte the server reports, expired ones (404) are dropped.
3. **Channel.** Without a usable session, the titles of the channel's uploads are listed (1 unit per 50 videos, once per run). An existing video with the same title stops the run with an explanation; `--adopt` records it instead. `plan` therefore requires unique titles.

A lock file (`flock`) stops two runs from working at the same time.

## Failure handling

| Failure | Handling |
|---|---|
| Network error, HTTP 500/502/503/504 | Up to 5 retries with exponential backoff and jitter; each attempt is charged to the quota count. |
| Interrupted upload | Ask the server for the received range, continue from there; never assume how much arrived. After 5 failures in a row the video is marked failed and the session is kept for the next run. |
| HTTP 401 | Refresh the access token once and repeat. `invalid_grant` on refresh ends the run with the instruction to run `auth`. |
| 403/429 `quotaExceeded`, `dailyLimitExceeded`, `uploadLimitExceeded`, `uploadRateLimitExceeded` | Stop the whole run cleanly with the time of the next quota reset in Indian time. Short-term `rateLimitExceeded` is retried with backoff first. |
| Quota about to run out | Before a video starts, its remaining cost must fit into today's allowance minus a reserve; otherwise the run stops before that video. |
| A side step fails (thumbnail, captions, playlist) | Recorded as `failed`; the other steps still run; the next run retries only that step. |
| The upload itself is refused (400, 401, 403) | The run stops: the same cause would hit every later video. |
| Publish time in the past, or closer than `--lead-minutes` | The video is skipped and reported; `--reschedule` shifts all not-yet-uploaded videos. A past `publishAt` is never sent, because YouTube would publish at once. |
| Process killed, power cut | State and session are on disk; the next run resumes. Covered by the self-test for three moments: during the upload, after the upload but before the record, and with the state file lost. |
| Wrong channel | Every API command compares `channels.list(mine)` with the confirmed channel before anything else. |
| File differs from the checked one | Size and SHA-256 are compared with the quality-control record before upload; a mismatch stops the run. |

Known limits: a playlist entry can be doubled if the state file is lost and a video is adopted (`verify` reports doubled entries); playlist order follows upload order, so `--only` out of order leaves that video at the end of its playlists; `verify` reads caption presence from `contentDetails.caption` instead of `captions.list`, which would cost 50 units per video.

## Security

- **No passwords.** Sign-in happens in the owner's browser on Google's page. The tool receives a one-time code on `127.0.0.1`, protected by PKCE (S256) and a random `state` value that is compared before the code is used.
- **Secrets outside the repository.** `client_secret.json`, `token.json` and `sessions.json` live in `~/.config/git-mastery-youtube/` (directory 700, files 600, created with that mode). `.gitignore` additionally blocks files with those names inside the repository.
- **Nothing secret is printed or logged.** Tokens are never written to output; the authorization header is left out of dry-run output; the loopback server does not log request lines (they contain the code); `state.json`, the reports and the logs hold no credential. The self-test asserts this for state and output.
- **Least privilege.** Two scopes: `youtube.upload` and `youtube.force-ssl` (needed for captions and playlists).
- **Fixed endpoints.** Google's addresses are constants; the addresses inside the client file are ignored. Requests go over HTTPS only. Downloads are accepted only from `github.com` and `*.githubusercontent.com` and are checked by size and SHA-256.
- **Safe defaults.** Every insert is `private` with a future `publishAt`; there is no delete command; `--dry-run` on every command prints the requests without reading a token or touching the network.

## Tests

`tools/youtube_publish.py --selftest` runs 24 offline tests in about ten seconds: parsing of all 201 metadata entries, the curriculum and the QC record; schedule arithmetic across midnight, month end, year end and a leap day with RFC 3339 output; description, tag and chapter rules; the OAuth URL and PKCE pair; quota accounting across a Pacific-time day change; and, against the local fake server, the full pipeline, a dropped connection, a killed process at three moments, a failed side step, retries on 503, token refresh on 401, the quota stop, the wrong-channel stop, past publish times with and without `--reschedule`, `verify` differences, `retime`, the dry run and the report. The fake server checks the SHA-256 of what it received, so a resumed upload is proven byte-exact.
