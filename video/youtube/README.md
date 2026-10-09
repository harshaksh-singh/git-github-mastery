# Publishing the 201 videos on YouTube

This folder holds the plan, the state and the reports of the YouTube release.
The work is done by one tool, `tools/youtube_publish.py`. It needs Python 3 and
nothing else: no package has to be installed.

What the tool does for each video, in the order of the course:

1. takes the MP4 from this Mac, or downloads it from the GitHub release and checks its size and SHA-256 against the quality-control record;
2. uploads it to your channel as **private**, with the time at which YouTube will make it public;
3. sets the thumbnail, uploads the English captions, adds the video to two playlists (the whole course, and its part);
4. reads the video back from YouTube and compares it with the plan;
5. writes every step to `state.json`, so that a second run continues where the first one stopped and never uploads a video twice.

What the tool never does: it never deletes anything on YouTube (it has no delete command), it never uploads a video as public, it never asks for or stores a password, and it never prints a token.

All facts about YouTube and Google in this guide were read from the official documentation on **10 October 2026**. Each one has its source in [section 9](#9-what-the-documentation-says). Limits have changed several times over the years, so read that section again if you come back to this much later.

## 1. One-time setup (about 20 minutes)

You need a web browser signed in to the Google account that owns the YouTube channel. Every command below is typed in Terminal, in the course folder:

```sh
cd ~/git-mastery
```

### 1.1 Verify the channel by phone

Without this, YouTube accepts only videos up to 15 minutes and no custom thumbnails. 155 of the 201 videos are longer than 15 minutes.

1. Open <https://www.youtube.com/verify>.
2. Enter a phone number, choose text message or voice call, enter the code that arrives.
3. Check the result: open <https://studio.youtube.com>, click **Settings** (bottom left), **Channel**, **Feature eligibility**. The box **Intermediate features** must say **Enabled**.

Later, `whoami` also prints whether the channel may upload long videos.

### 1.2 Create a Google Cloud project

The project is only a container for the permission to call the YouTube API. It costs nothing.

1. Open <https://console.cloud.google.com/projectcreate>. Accept the terms if Google asks.
2. **Project name**: `git-mastery-youtube`. Leave **Location** as it is. Click **Create**.
3. Wait for the notification, then choose the new project in the project picker at the top of the page.

### 1.3 Enable the YouTube Data API v3

1. Open <https://console.cloud.google.com/apis/library/youtube.googleapis.com> (check that the project picker still shows `git-mastery-youtube`).
2. Click **Enable**.

### 1.4 Configure the consent screen

This is the page Google shows when the tool asks for access to your channel.

1. Open <https://console.cloud.google.com/auth/overview> and click **Get started**.
2. **App name**: `Git Mastery Uploader`. **User support email**: your address. **Next**.
3. **Audience**: choose **External**. **Next**.
4. **Contact information**: your address. **Next**. Tick the agreement, **Continue**, **Create**.
5. Open **Audience** in the left menu (<https://console.cloud.google.com/auth/audience>). Under **Test users** click **Add users**, enter the Google address that owns the YouTube channel, **Save**.

The app is now in publishing status **Testing**. That is enough to upload, with one drawback: see 1.6.

(The names of the buttons are the ones Google used on the day this guide was written. Google rearranges this console from time to time; the three things that matter are the user type External, your address as test user, and the Desktop client of the next step.)

### 1.5 Create the OAuth client and save its file

1. Open <https://console.cloud.google.com/auth/clients> and click **Create client**.
2. **Application type**: **Desktop app**. **Name**: `git-mastery-cli`. Click **Create**.
3. In the dialog that appears, click **Download JSON**. Do it now: Google shows the client secret only at this moment.
4. Move the downloaded file to the place where the tool looks for it:

```sh
mkdir -p ~/.config/git-mastery-youtube
chmod 700 ~/.config/git-mastery-youtube
mv ~/Downloads/client_secret_*.json ~/.config/git-mastery-youtube/client_secret.json
chmod 600 ~/.config/git-mastery-youtube/client_secret.json
```

This file and the token that step 2.3 creates are the only secrets. They stay in `~/.config/git-mastery-youtube/`, outside the repository. Never copy them into `~/git-mastery`.

### 1.6 Decide: stay in Testing, or publish the consent screen

Google's rule: while the consent screen is in **Testing**, the sign-in of step 2.3 expires after **7 days**. The full upload takes about 12 days (section 3), so in Testing you must run `auth` again once, when the tool tells you so. Nothing is lost when that happens: the run stops, you sign in again, the next run continues.

To avoid it: on <https://console.cloud.google.com/auth/audience> click **Publish app** and confirm. The status becomes **In production**. Because the app asks for access to YouTube and has not been reviewed by Google, the sign-in page then shows a warning "Google hasn't verified this app"; click **Advanced**, then **Go to Git Mastery Uploader (unsafe)**. That warning is about the app you just created yourself. You do not need Google's verification for your own use.

Either choice works. For an unattended daily run, **In production** is the better one.

### 1.7 About the API audit (read this once)

In 2020 YouTube announced that videos uploaded through an API project that has not passed YouTube's compliance audit are locked as private. The documentation is no longer consistent about this (details in section 9, row "Unaudited projects"): the reference page of the upload method now says such videos are *not* restricted, one Help Center page still describes the lock. **This guide therefore does not assume either.** You find out with one video, in step 2.5, before the other 200 are uploaded.

If the test video is locked as private (YouTube sends an email, and YouTube Studio shows "Private (locked)"), the remedy that the documentation gives is the audit: fill in the *YouTube API Services - Audit and Quota Extension Form*, <https://support.google.com/youtube/contact/yt_api_form>. YouTube's API team answers by email; how long that takes is not stated. The same form is the way to ask for a higher daily quota.

## 2. The commands, in order

Every command accepts `--dry-run`: it then prints what it would send or write and does nothing else.

### 2.1 `plan`: build the schedule

```sh
tools/youtube_publish.py plan --start "2026-10-20 09:00"
```

`--start` is the publish time of V001 in Indian time (Asia/Kolkata). Each later video follows 5 hours after the one before it (`--gap-hours 5`). The command writes [`PLAN.md`](PLAN.md) (for you to read) and `plan.json` (what will be sent, word for word), and checks every title, description, tag list and chapter list against YouTube's limits. A violation is reported and the video is held back; text is never shortened silently.

### 2.2 `check`: preflight

```sh
tools/youtube_publish.py check
```

For all 201 videos: metadata present and unchanged since the plan, thumbnail present and a 16:9 PNG within the limits, captions parse, chapters valid, quality-control status PASS, and the MP4 on GitHub answers with exactly the size the quality control recorded. The only network traffic is one HEAD request per video to GitHub. Go on only when it ends with `201 of 201 videos ready, 0 problems`.

### 2.3 `auth`: sign in

```sh
tools/youtube_publish.py auth
```

Your browser opens Google's page. Choose the account, then the channel, click **Continue** on the warning, tick both permissions (manage your YouTube videos; see, edit and delete your YouTube content), **Continue**. The browser says "Signed in"; the terminal says where the token was stored (`~/.config/git-mastery-youtube/token.json`, readable only by you). The tool never sees your password: you type it, if at all, into Google's own page.

### 2.4 `whoami`: confirm the channel

```sh
tools/youtube_publish.py whoami
```

It prints the channel title and ID, whether long videos are allowed, and the name of category 27 (it should be "Education"). If this is the channel that should receive the course:

```sh
tools/youtube_publish.py whoami --confirm
```

From now on `upload`, `verify` and `retime` stop at once if the token belongs to any other channel. (Instead of confirming, you can pass `--channel-id UC...` to each of those commands.)

### 2.5 Test with one video

```sh
tools/youtube_publish.py upload --only V001 --dry-run     # read what would be sent
tools/youtube_publish.py upload --only V001
```

Then look at it in YouTube Studio (<https://studio.youtube.com>, **Content**): visibility **Scheduled** with the right date, your thumbnail, **Subtitles** shows English, the description has the chapter list, the video is in two playlists.

To be sure about section 1.7 before the mass upload, let this one video go public first. The practical way: make the plan start two or three hours from now, upload V001, wait until its time has passed, then run `verify`. If `verify` reports no difference, the video became public on schedule and you can go on. If it says `privacy: still private after the publish time`, see section 5.

### 2.6 `verify`: compare YouTube with the plan

```sh
tools/youtube_publish.py verify
```

Reads every uploaded video back and compares title, description, tags, category, language, publish time, privacy (private before its time, public after), playlists, custom thumbnail and captions. Differences are listed on screen and in `VERIFY.md`. It costs about 15 quota units for all 201.

### 2.7 Upload the rest

```sh
tools/youtube_publish.py upload --next 5      # the next five that are not finished
tools/youtube_publish.py upload --all         # everything that is left
```

`--all` stops by itself when today's quota is used and tells you when to run it again. Run it once a day until it reports 201 of 201, by hand or with the daily job of section 6.

### 2.8 `report`

```sh
tools/youtube_publish.py report
```

Writes [`REPORT.md`](REPORT.md) and `report.csv`: per video its URL, publish time and the state of each step, plus totals and the quota used per day. `upload` writes it too at the end of every run. `status` is the same command.

## 3. Quota: why the upload takes about 12 days

Google gives every project a daily allowance, reset at midnight Pacific Time (12:30 in India from March to November, 13:30 otherwise).

| What | Cost | Daily allowance |
|---|---|---|
| Upload a video (`videos.insert`) | 1 call, in its own bucket | 100 calls |
| Set a thumbnail | 50 units | |
| Upload captions | 400 units | 10,000 units for everything |
| Add to one playlist | 50 units (two playlists per video: 100) | except uploads |
| Create a playlist | 50 units (13 playlists, once) | |
| Read a video, a channel or a list page | 1 unit | |

One complete video costs 1 upload call and **551 units** (50 + 400 + 100 + 1). The tool keeps 100 units in reserve, so 9,900 / 551 = **17 videos per day**, and 201 videos need **12 daily runs**. The limit that binds is the 10,000 units, mostly the captions, not the 100 uploads.

The tool counts every call it makes, per Pacific day, in `state.json`. Before each video it checks that the whole video still fits; if not it stops with a message such as `rerun after 2026-10-21 12:40 Asia/Kolkata`. It never starts a video it cannot finish that day.

Publishing is slower than uploading (4.8 videos per day at a 5-hour gap against 17 uploads per day), so the uploads stay ahead of the schedule as long as the first run happens before the first publish time.

If you get a higher quota from Google (the form in section 1.7), tell the tool: `upload --all --daily-units 50000`.

Separately from the API quota, YouTube limits how many videos a channel may upload per day. The Help Center gives no number: it only says the limit is "limited" with phone verification and "higher" with advanced features. If the channel hits it, YouTube answers `uploadLimitExceeded`; the tool stops cleanly and the next day's run continues.

Data volume: the 201 files are 15.06 GB in total, about 1.3 GB down and 1.3 GB up per day at 17 videos.

## 4. Changing the schedule

**Before anything is uploaded:** run `plan` again with another `--start` or `--gap-hours`.

**Later, for the videos not yet uploaded:** keep the earlier times and give a new time from a certain video on:

```sh
tools/youtube_publish.py plan --start "2026-11-05 09:00" --from V060 --gap-hours 6
```

V001 to V059 keep their times; V060 is published at the given time, the rest follow. The command refuses a time that is not after V059.

**For videos already uploaded and still private:** make the new plan as above, then

```sh
tools/youtube_publish.py retime --dry-run
tools/youtube_publish.py retime
```

`retime` changes only the publish time of those videos (51 units each). A video that is already public cannot be rescheduled; YouTube allows a publish time only for a private video that was never published.

**When a run comes late** and some publish times have already passed, `upload` skips those videos and says so (it never sends a time in the past, because YouTube would publish such a video at once). Either re-plan with `--from`, or let the tool do it: `upload --all --reschedule` moves all not-yet-uploaded videos later by a whole number of gaps, just enough that the next one is in the future, and rewrites `plan.json` and `PLAN.md`.

## 5. When something fails

State is saved after every step. In nearly every case the fix is: read the message, remove the cause, **run the same command again**.

| What you see | What it means | What to do |
|---|---|---|
| `STOPPED: ... rerun after ...` | Today's quota is used. Not an error. | Run again after the given time. |
| `no token yet` or `Google no longer accepts the stored refresh token` | Not signed in, or the 7-day limit of Testing mode (1.6) passed, or you removed the app's access. | `tools/youtube_publish.py auth`, then the same command again. |
| `the token belongs to channel ...` | You signed in to another channel. | `auth` again and choose the right channel. |
| `upload interrupted ... retry` and later `the upload kept failing` | Network trouble. The upload session is kept. | Run again; the upload continues at the byte where it stopped. |
| `thumbnail FAILED: HTTP 403` | The channel may not set custom thumbnails. | Verify the channel by phone (1.1), run again. Only the thumbnail is retried. |
| `HTTP 403 uploadLimitExceeded` | The channel's own daily upload limit. | Run again 24 hours later. |
| The upload is refused or `verify` shows a duration far below the real one, for a video longer than 15 minutes | The channel is not verified for long videos. | 1.1, then delete the truncated or rejected video in YouTube Studio, remove that video's entry from `state.json`, run again. |
| `captions FAILED: HTTP 400` on the very first video | YouTube did not accept an empty track name. Not confirmed either way in the documentation. | Put `{"caption_name": "English"}` in `video/youtube/config.json`, run `plan` again, run again. |
| `the channel already has a video with this exact title ... state.json has no record` | A video exists that the tool did not record, for example after `state.json` was lost. Nothing was uploaded. | If it is the same video: run again with `--adopt`. Otherwise rename or remove it in YouTube Studio. |
| `SKIPPED, its publish time ... is in the past` | The run is late. | Section 4, last paragraph. |
| `SKIPPED, the plan lists violations` | A text is over a limit. | Fix the text in `video/youtube-metadata.md` and `thumbnail-data.json`, run `plan` and `check` again. |
| `verify`: `privacy: still private after the publish time` | YouTube did not publish the video. If Studio shows it as locked, this is the audit case of 1.7. | Stop uploading. Request the audit (1.7). Per the Help Center, a video locked for this reason cannot be appealed and has to be uploaded again through an audited project or by hand. |
| `VERIFY FAILED: processingStatus is failed` | YouTube could not process the file. | Look at the video in Studio. If it is unusable, delete it there, remove its entry from `state.json`, run again. |
| `another youtube_publish.py run holds the lock` | A run is still working. | Wait for it. |
| The Mac was switched off in the middle | Nothing is lost. | Run again. |

Removing a video's entry from `state.json` is the only manual edit that is ever needed, and only after you deleted that video on YouTube yourself. Do it with care: an entry with a `video_id` is what stops a second upload.

To start a clean test of the tool itself at any time: `tools/youtube_publish.py --selftest` (offline, about ten seconds, touches neither YouTube nor your state).

## 6. Run it every day without you

`video/youtube/run-daily.sh` runs `upload --all`, then `report`, and appends everything to `video/youtube/logs/YYYY-MM-DD.log`. It keeps the Mac awake while it works. Try it once by hand:

```sh
video/youtube/run-daily.sh
```

To have macOS start it every day at 14:00 (after the quota reset in both halves of the year), save the following as `~/Library/LaunchAgents/com.gitmastery.youtube.plist`. This is an example; nothing was installed for you.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.gitmastery.youtube</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>/Users/apple/git-mastery/video/youtube/run-daily.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>/tmp/com.gitmastery.youtube.out</string>
  <key>StandardErrorPath</key><string>/tmp/com.gitmastery.youtube.err</string>
</dict>
</plist>
```

```sh
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.gitmastery.youtube.plist   # switch on
launchctl bootout   gui/$(id -u)/com.gitmastery.youtube                                # switch off
```

The Mac must be on and you must be logged in at that time; if it was asleep, launchd runs the job when it wakes. In Testing mode (1.6) the job stops after 7 days with the "refresh token" message in the log; run `auth` and it continues the next day. Remove the job when the report says 201 of 201.

## 7. Settings you can change

Defaults are built into the tool. To change one, create `video/youtube/config.json` with only the keys you want to change, then run `plan` again (the settings are copied into `plan.json`).

| Key | Default | Meaning |
|---|---|---|
| `category_id` | `"27"` | Video category. `whoami` prints its name for India. |
| `language`, `audio_language`, `caption_language` | `"en"` | Language of the text, of the speech, of the caption track. |
| `caption_name` | `""` | Name of the caption track shown in the player menu. |
| `made_for_kids` | `false` | The "made for kids" declaration. |
| `contains_synthetic_media` | `null` | `true` or `false` sends YouTube's "altered or synthetic content" declaration; `null` sends nothing. See section 9. |
| `notify_subscribers` | `true` | YouTube's default. `false` sends no notification for the uploads. |
| `playlist_privacy` | `"public"` | Privacy of the 13 playlists when they are created. A private video inside a public playlist stays invisible until it is published. |
| `course_playlist_title`, `part_playlist_title`, `playlist_description` | see `PLAN.md` | Playlist texts. |
| `link_line` | `Course book, labs and exercises: https://github.com/harshaksh-singh/git-github-mastery` | Last line of every description. |
| `base_tags`, `part_tags`, `video_tags` | see `plan.json` | Tags. |

About the tags: `video/youtube-metadata.md` has a title and a description for each video but **no tags**. The tool therefore builds them: seven course tags, two or three tags for the part, and the Git or GitHub command of the video where it has one (from `thumbnails/thumbnail-data.json`, for example `git merge-base`). The largest set is 163 of the 500 characters allowed. To add tags for one video: `{"video_tags": {"V042": ["git stash"]}}`.

## 8. Files in this folder

| File | Written by | In Git? |
|---|---|---|
| `README.md`, `DESIGN.md`, `run-daily.sh` | by hand | yes |
| `plan.json`, `PLAN.md` | `plan` (and `upload --reschedule`) | yes |
| `state.json` | `whoami --confirm`, `upload`, `verify`, `retime` | yes; it holds video IDs and step states, no secret |
| `REPORT.md`, `report.csv` | `report`, `upload` | yes |
| `VERIFY.md` | `verify` | yes |
| `config.json` | you, optional | yes |
| `logs/`, `.lock` | `run-daily.sh`, `upload` | no (`.gitignore`) |
| `~/.config/git-mastery-youtube/client_secret.json`, `token.json`, `sessions.json` | you, `auth`, `upload` | outside the repository, mode 600 |

## 9. What the documentation says

Read on 10 October 2026. "Not confirmed" means the official pages did not state it, or contradict each other.

### Signing in (OAuth 2.0)

| Fact | Source |
|---|---|
| Desktop apps use the authorization-code flow with a loopback redirect: "`http://127.0.0.1:port` or `http://[::1]:port`", "start an HTTP listener on a random available port". | <https://developers.google.com/identity/protocols/oauth2/native-app> |
| PKCE is supported; the code verifier has 43 to 128 characters from `A-Z a-z 0-9 - . _ ~`; `S256` is recommended: the challenge is the unpadded Base64URL of the SHA-256 of the verifier. | same page |
| Authorization endpoint `https://accounts.google.com/o/oauth2/v2/auth`; token endpoint `https://oauth2.googleapis.com/token`; exchange with `grant_type=authorization_code` and the `code_verifier`; refresh with `grant_type=refresh_token`. "Refresh tokens are always returned for installed applications." | same page |
| A `state` value is recommended because the redirect address can be guessed. | same page |
| Scopes: `videos.insert` and `thumbnails.set` accept `youtube.upload`; `captions.insert` accepts only `youtube.force-ssl` (or `youtubepartner`); `playlists.insert` and `playlistItems.insert` accept `youtube.force-ssl`. The tool asks for `youtube.upload` and `youtube.force-ssl`. | <https://developers.google.com/youtube/v3/docs/videos/insert>, <https://developers.google.com/youtube/v3/docs/thumbnails/set>, <https://developers.google.com/youtube/v3/docs/captions/insert>, <https://developers.google.com/youtube/v3/docs/playlists/insert>, <https://developers.google.com/youtube/v3/docs/playlistItems/insert> |
| Testing mode: "A Google Cloud Platform project with an OAuth consent screen configured for an external user type and a publishing status of "Testing" is issued a refresh token expiring in 7 days", unless only name, email and profile scopes are requested. | <https://developers.google.com/identity/protocols/oauth2> |
| Testing mode: up to 100 test users; "Authorizations by a test user will expire seven days from the time of consent." In production an unverified app that requests sensitive scopes shows an "Unverified apps" warning. | <https://support.google.com/cloud/answer/15549945> |
| A refresh token also stops working if the user revokes access or it "has not been used for six months"; at most 100 refresh tokens per account and client. | <https://developers.google.com/identity/protocols/oauth2> |
| The client secret is shown only when the client is created. | <https://support.google.com/cloud/answer/15549257> |
| Exact names of the buttons in the Google Cloud console (section 1.2 to 1.6). | **Not confirmed** from documentation; they are described as the help pages name the sections (Google Auth Platform: Audience, Clients; "Publish app"). |

### Uploading (`videos.insert`)

| Fact | Source |
|---|---|
| Upload address `POST https://www.googleapis.com/upload/youtube/v3/videos`; maximum file size 256 GB; media types `video/*`, `application/octet-stream`. | <https://developers.google.com/youtube/v3/docs/videos/insert> |
| Resumable protocol: start with `POST ...?uploadType=resumable&part=...`, the JSON video resource and the headers `X-Upload-Content-Length` and `X-Upload-Content-Type`; the session address comes back in the `Location` header; send the file with `PUT`; `201` means done. After an interruption or a 500, 502, 503 or 504: send an empty `PUT` with `Content-Range: bytes */TOTAL`; `308` with `Range: bytes=0-N` says how much arrived; continue at N+1 with `Content-Range: bytes FIRST-LAST/TOTAL`; use exponential backoff. A `404` means the session expired and the upload must start again. Pieces, if used, must be multiples of 256 KB. | <https://developers.google.com/youtube/v3/guides/using_resumable_upload_protocol> |
| Properties that can be set on insert: `snippet.title`, `snippet.description`, `snippet.tags[]`, `snippet.categoryId`, `snippet.defaultLanguage`, `status.embeddable`, `status.license`, `status.privacyStatus`, `status.publicStatsViewable`, `status.publishAt`, `status.selfDeclaredMadeForKids`, `status.containsSyntheticMedia`, `recordingDetails.recordingDate`, localizations. | <https://developers.google.com/youtube/v3/docs/videos/insert> |
| `snippet.defaultAudioLanguage` exists in the video resource ("the language spoken in the video's default audio track") but is not in the list above. The tool sends it; `verify` shows whether YouTube kept it. | **Not confirmed** that insert accepts it. <https://developers.google.com/youtube/v3/docs/videos> |
| Title: "maximum length of 100 characters and may contain all valid UTF-8 characters except < and >". | <https://developers.google.com/youtube/v3/docs/videos> |
| Description: "maximum length of 5000 bytes and may contain all valid UTF-8 characters except < and >". Bytes, not characters. | same page |
| Tags: "maximum length of 500 characters"; commas between tags count; a tag with a space counts two more for quotation marks ("Foo Baz" counts nine). | same page |
| `status.privacyStatus`: `private`, `public`, `unlisted`. If it is not given, the upload "defaults to public". The tool always sends `private`. | same page |
| `status.publishAt`: "can be set only if the privacy status of the video is private", ISO 8601, and only if "the video has never been published". A time in the past publishes the video "right away". With `videos.update`, `privacyStatus` must be sent as `private` again. | same page |
| `status.selfDeclaredMadeForKids` is the owner's declaration on insert and update. | same page |
| `snippet.categoryId` is checked against `videoCategories.list`; a wrong one gives `invalidCategoryId`. That 27 means Education is not stated on a documentation page. | **Not confirmed**; `whoami` reads the name from the API (1 unit). <https://developers.google.com/youtube/v3/docs/videoCategories/list> |
| `notifySubscribers` defaults to true; "a channel owner who is uploading many videos might prefer to set the value to False". | <https://developers.google.com/youtube/v3/docs/videos/insert> |
| Whether subscribers are notified at upload time or at the scheduled publish time. | **Not confirmed.** |
| Unaudited projects: the 28 July 2020 entry of the revision history says uploads "from unverified API projects created after 28 July 2020 will be restricted to private viewing mode" until the project passes an audit. Today's reference for `videos.insert` and for `status.privacyStatus` (pages updated 8 October 2026) says: "Videos uploaded from unverified API projects are not restricted to private viewing mode." The automatic summary at the top of the video resource page, and the Help Center page "Videos locked as private", still describe the lock ("you will not be able to appeal ... re-upload the video via a verified API service"). | **Not confirmed: the official pages contradict each other.** Test with one video (2.5). <https://developers.google.com/youtube/v3/revision_history>, <https://developers.google.com/youtube/v3/docs/videos/insert>, <https://developers.google.com/youtube/v3/docs/videos>, <https://support.google.com/youtube/answer/7300965> |
| The audit: needed "to request additional quota beyond the default allocation"; started with the Audit and Quota Extension Form; "A member of YouTube's API Services team will contact you". Duration is not stated. | <https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>, form: <https://support.google.com/youtube/contact/yt_api_form> |
| Disclosure of AI content is required for realistic altered or generated content (a real person appearing to say something, altered footage of real events, realistic invented scenes). Whether a synthetic narration voice over slides and terminal recordings needs it is not stated; the listed examples that need no disclosure include "production assistance" and clearly unrealistic content. | **Not confirmed** for this course; the owner decides (`contains_synthetic_media`). <https://support.google.com/youtube/answer/14328491> |

### Thumbnail, captions, playlists

| Fact | Source |
|---|---|
| `thumbnails.set`: `POST https://www.googleapis.com/upload/youtube/v3/thumbnails/set?videoId=...`; maximum 50 MB; `image/jpeg`, `image/png`; errors include 403 "doesn't have permissions to upload and set custom video thumbnails" and 429 `uploadRateLimitExceeded`. | <https://developers.google.com/youtube/v3/docs/thumbnails/set> |
| Help Center on thumbnails: JPG or PNG, 16:9, minimum width 640 pixels, limit 2 MB on mobile and 50 MB on desktop; "There's a limit to how many custom thumbnails a channel can upload each day" (no number). The course thumbnails are 1280x720 PNG, at most 0.48 MB. | <https://support.google.com/youtube/answer/72431> |
| Custom thumbnails and videos longer than 15 minutes are "intermediate features", unlocked by phone verification. | <https://support.google.com/youtube/answer/9890437>, <https://support.google.com/youtube/answer/171664> |
| "By default, you can upload videos that are up to 15 minutes long. Verified accounts can upload videos longer than 15 minutes." Maximum 256 GB or 12 hours. | <https://support.google.com/youtube/answer/71673> |
| The API reports this per channel as `status.longUploadsStatus` (`allowed`, `eligible`, `disallowed`). | <https://developers.google.com/youtube/v3/docs/channels> |
| Daily upload limit per channel: uploads have a "limited daily limit" with phone verification and a "higher daily limit" with advanced features; after hitting a limit "wait 24 hours". No number is given. The API error is `uploadLimitExceeded` (403). | Number **not confirmed**. <https://support.google.com/youtube/answer/9890437>, <https://developers.google.com/youtube/v3/docs/videos/insert> |
| `captions.insert`: `POST https://www.googleapis.com/upload/youtube/v3/captions`, maximum 100 MB, `part=snippet`; required `snippet.videoId`, `snippet.language` (BCP-47), `snippet.name` (at most 150 characters); `captionExists` (409) if a track with the same language and name exists. | <https://developers.google.com/youtube/v3/docs/captions/insert>, <https://developers.google.com/youtube/v3/docs/captions> |
| Whether `snippet.name` may be the empty string. | **Not confirmed**; the tool sends `""` and can be told otherwise (section 5). |
| SubRip (`.srt`) is a supported caption format; "The file must be in plain UTF-8." | <https://support.google.com/youtube/answer/2734698> |
| `playlists.insert`: required `snippet.title`; optional `snippet.description`, `status.privacyStatus`, `snippet.defaultLanguage`; error when the channel has "the maximum number of playlists allowed". `playlistItems.insert`: required `snippet.playlistId`, `snippet.resourceId`. | <https://developers.google.com/youtube/v3/docs/playlists/insert>, <https://developers.google.com/youtube/v3/docs/playlistItems/insert> |
| Maximum length of a playlist title. | **Not confirmed**; the tool refuses more than 150 characters. The longest title planned has 72. |
| Creating playlists has a "limited daily limit" (higher for public playlists with advanced features); no number. | Number **not confirmed**. <https://support.google.com/youtube/answer/9890437> |

### Chapters and scheduling

| Fact | Source |
|---|---|
| Chapters come from "a list of timestamps and titles" in the description; "the first timestamp you list starts with 00:00"; "at least three timestamps listed in ascending order"; "The minimum length for video chapters is 10 seconds." Channels with active strikes do not get chapters. | <https://support.google.com/youtube/answer/9884579> |
| The Help Center writes the first timestamp as `00:00`; the course files write `0:00`. Whether `0:00` is accepted equally is not stated. | **Not confirmed**; look at V001 after the test upload (2.5). |
| "Add chapters" and clickable links in descriptions appear in the feature table under advanced features. | <https://support.google.com/youtube/answer/9890437>. What this means for a phone-verified channel is **not confirmed**; if the test video shows no chapters, apply for advanced features (<https://support.google.com/youtube/answer/9891124>). |
| Scheduled publishing sets a private video "to go public at a specific time". The date shown under a video follows Pacific time. | <https://support.google.com/youtube/answer/1270709> |

### Quota

| Fact | Source |
|---|---|
| "Projects that enable the YouTube Data API have a default quota allocation of 100 search.list calls, 100 videos.insert calls, and 10,000 units per day combined for all other endpoints." "Daily quotas reset at midnight Pacific Time (PT)." | <https://developers.google.com/youtube/v3/determine_quota_cost> |
| "The search.list and videos.insert methods have their own quota buckets. Each of these methods has a default daily limit of 100 per day. The quota cost is 1 per call." | same page |
| History: an upload cost about 1600 units until 4 December 2025, then about 100; since 1 June 2026 it is charged to its own bucket. One sentence in the summary box of the quota page still says 1600. | <https://developers.google.com/youtube/v3/revision_history> |
| Costs: `thumbnails.set` 50, `captions.insert` 400, `captions.list` 50, `playlists.insert` 50, `playlistItems.insert` 50, `videos.update` 50; `videos.list`, `channels.list`, `playlists.list`, `playlistItems.list`, `videoCategories.list` 1 each. "Every API request, even if invalid, will cost at least one quota point." Each extra page of a list costs again. | <https://developers.google.com/youtube/v3/determine_quota_cost> |
| More quota is requested with the Quota extension request form. | <https://developers.google.com/youtube/v3/getting-started> |
