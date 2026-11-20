# Using Claude Code from a phone only (Android app / claude.ai/code in a mobile browser)

Research date: 2026-11-20. Official Anthropic docs (code.claude.com) were fetched live and reflect current behavior. Blog/news items are dated inline; anything from 2025 or early 2026 may be outdated.

## 1. What can and can't be done in Claude Code from the mobile app (cloud sessions, files, previews, artifacts, permissions, voice)?

### Takeaway
On a phone, the Claude app's **Code** tab (or claude.ai/code in a browser) is a remote control for **cloud sessions** that run on Anthropic's Linux VMs against a GitHub repo, so no computer is needed. You can start sessions, chat and steer while Claude works, answer its questions, switch permission mode, review diffs and create PRs. Code never runs on the phone itself. Remote Control and Dispatch both need a computer that stays on, so they don't suit a phone-only user.

### Cited Findings
**What the app is and where the work runs**
- "The Claude app for iOS and Android is a client for Claude Code sessions rather than a place where code runs." There is no separate Claude Code mobile app: cloud sessions and Remote Control live in the **Code** tab of the normal Claude app. — [Claude Code on mobile docs](https://code.claude.com/docs/en/mobile)
- To start a session, tap **Code**, or open `claude.ai/code/new` on the phone. If the Code tab is missing, your plan or organization may not include it. — [Mobile docs](https://code.claude.com/docs/en/mobile)
- Starting a cloud session from the phone: "select a repository and branch, describe the task, and submit it." Sessions persist across devices and keep running after you put the phone away. — [Mobile docs](https://code.claude.com/docs/en/mobile)
- The options compared:
  - Cloud sessions and Projects run in the cloud and "continue with your laptop closed."
  - Remote Control and Dispatch drive your own machine, which "needs to stay on."
  - Dispatch requires Pro, Max or Ultra. — [Mobile docs](https://code.claude.com/docs/en/mobile)
- Cloud sessions are available on Pro, Max, Ultra and Team plans, and to Enterprise users with premium seats. They count toward your plan's usage limits, and "there's no separate charge for the cloud VM." — [Claude Code in the cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)
- GitHub access:
  - Cloud sessions need GitHub, either through the Claude GitHub App or through `/web-setup`.
  - `/web-setup` is run from a terminal, so it is not an option for phone-only users. The GitHub App is authorized during web onboarding.
  - Cloning and PR creation require GitHub; GitLab and Bitbucket only work via a local bundle, which needs a computer. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)

**Permissions**
- Cloud sessions offer the **Accept edits**, **Plan** and **Auto** modes.
- "You can't select Bypass permissions from the app."
- Remote Control sessions also offer Manual. — [Mobile docs](https://code.claude.com/docs/en/mobile)
- You can change a cloud session's permission mode from the mode dropdown when you create the task and while it runs. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)

**Unsupported commands and command differences**
- "Local-only commands … such as `/plugin` and `/resume`, don't work from the app." — [Mobile docs](https://code.claude.com/docs/en/mobile)
- In cloud sessions:
  - `/model`, `/effort` and `/rename` take an argument (e.g. `/model sonnet`) instead of opening a picker.
  - `/compact`, `/context` and `/clear` work.
  - `/config` opens Settings instead. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)

**Viewing changes and files**
- After Claude pushes, a **Changes** card shows the lines added and removed (e.g. `+42 -18`). Tap it to open a diff view.
- In the diff view you can leave inline comments that go to Claude with your next message, and compare against another branch.
- A file can be missing from the diff until Claude commits and pushes, so "ask Claude to commit and push." — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)
- If you send a message while Claude is working, it queues. Tap the ✕ on it to take it back. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)
- Long sessions auto-compact. Scroll up in the app to read the original messages. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)

**Idle sessions and expiry**
- After a few minutes without activity, a session's VM pauses with its files saved. Your next message restores it.
- A paused VM can later be reclaimed. Reopening the session then restores the conversation but not any background shell commands that were still running. — [Cloud environments docs](https://code.claude.com/docs/en/cloud-environments); [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)

**What the cloud VM has**
- An Ubuntu 24.04 x86_64 VM with 4 vCPUs and 16 GB of RAM.
- Pre-installed:
  - Python 3, with pytest and other tools
  - Node 20/21/22, with npm and chromedriver
  - OpenJDK 21 with Maven and Gradle
  - Go, Rust and C/C++
  - Docker
  - Chrome for Testing at `/usr/bin/google-chrome`
  - git and `gh`
- The Android SDK is **not** listed as pre-installed. — [Cloud environments docs](https://code.claude.com/docs/en/cloud-environments)
- Network:
  - The default network level is **Limited**.
  - The allowlist includes npm, PyPI, GitHub, `maven.google.com`, the gradle.org hosts, `developer.android.com` and `*.googleapis.com`.
  - Other domains must be added in the environment's **Allowed domains** setting. — [Cloud environments docs](https://code.claude.com/docs/en/cloud-environments)
- Time limits:
  - A foreground command waits 2 minutes by default, and Claude can ask for up to 10.
  - Longer commands move to the background for up to 30 more minutes.
  - A setup script that takes over about 5 minutes isn't cached. — [Cloud environments docs](https://code.claude.com/docs/en/cloud-environments)

**Notifications**
- Push notifications ("notify me when the tests finish") are documented for **Remote Control**, which needs a computer.
- The mobile docs don't document push notifications for plain cloud sessions. — [Mobile docs](https://code.claude.com/docs/en/mobile)

**Voice**
- The Claude mobile app's microphone dictation works on iOS and Android for all plans.
- It supports 12 languages, including English, Spanish and German. Non-English is in beta.
- The audio recording is deleted after transcription by default. — [Claude Help Center: dictation](https://support.claude.com/en/articles/10065434-using-dictation-on-claude-mobile)
- A search summary of Anthropic's help center said dictation is available in Claude Code but voice mode isn't. I could not verify this in the fetched article text, which doesn't mention Claude Code. — [Help Center search result](https://support.claude.com/en/articles/10065434-using-dictation-on-claude-mobile)
- A GitHub feature request (Mar 2026) said the Claude Code mobile/web interface lacked the chat app's microphone button. The reporter's workaround was keyboard dictation, which they found worse. The issue was closed as "not planned" (stale) in May 2026. — [GitHub issue #36581](https://github.com/anthropics/claude-code/issues/36581)

**Artifacts (published pages)**
- An artifact is "a live, interactive web page" that Claude publishes to a private claude.ai URL. It updates in place, and you can share it publicly on Pro, Max and Ultra.
- Its limits:
  - It is one self-contained HTML or Markdown page, 16 MiB at most, with no backend.
  - A strict CSP allows scripts only from cdnjs, unpkg, jsDelivr, Tailwind and jQuery, and fonts only from Google Fonts.
  - External images are blocked, so images must be embedded.
  - fetch can't reach other domains.
  - The page can't start downloads itself. — [Artifacts docs](https://code.claude.com/docs/en/artifacts)
- The artifacts docs list the CLI, the desktop app, Claude Tag and Remote Control as supported surfaces. Cloud sessions are not explicitly listed, but the `/artifacts` delete key is described as working "outside a cloud session," which implies artifacts exist in cloud sessions. Availability from a phone-started cloud session is therefore plausible but not explicitly documented. — [Artifacts docs](https://code.claude.com/docs/en/artifacts)
- All artifacts are listed in a gallery at claude.ai/code/artifacts. — [Artifacts docs](https://code.claude.com/docs/en/artifacts)

**Older and conflicting reports**
- **Outdated:** Builder.io (Mar 2026) said "you can't start new sessions from mobile." That applied to Remote Control. Current docs say you can start cloud sessions from the app. — [Builder.io](https://www.builder.io/blog/claude-code-mobile-phone) vs [Mobile docs](https://code.claude.com/docs/en/mobile)
- **Early-preview problems (Oct 2025):**
  - The iOS app froze when the keyboard opened.
  - It had no "jump to bottom" button, no image pasting, and slash autocomplete didn't work.
  - Network domains had to be whitelisted.
  - There were no side-by-side diffs, and you couldn't validate work on the phone ("always stuck at 90 percent").
  - Many of these were preview bugs and are likely fixed; the diff view now exists. — [Every, "Vibe Check" (Oct 2025)](https://every.to/vibe-check/vibe-check-we-spent-a-weekend-trying-to-code-from-our-phones)

### Inferences
- For a phone-only user, the realistic setup is: Pro or Max plan, a GitHub account, the Claude GitHub App authorized, and cloud sessions started from the Code tab.
- Avoid anything that requires `/web-setup`, `--teleport`, Remote Control or Dispatch.
- Claude can test its own work inside the VM. It has headless Chrome and can run Playwright and take screenshots, which partly substitutes for the user having no devtools.
- Building Android APKs inside the cloud VM is possible in principle: Java, Gradle and the Google Maven host are allowed. But the Android SDK would need installing. Building in GitHub Actions is the more reliable route (see section 2).

### Gaps
- No official statement on whether Android-app cloud sessions show a live web "preview" pane like the Desktop app's. No such feature is documented for mobile.
- I could not confirm whether the microphone dictation button appears in the Code tab on Android specifically (as of Nov 2026).
- I could not confirm whether plain cloud sessions send phone push notifications when done.
- No exact launch date found for the Code tab on Android.

## 2. How do phone-only users view results: previews, published pages/artifacts, GitHub Pages, APKs built by GitHub Actions?

### Takeaway
The best-documented phone-only loop is GitHub Pages: have Claude build a static `index.html` game or app, point Pages at Claude's branch, and reload the URL on the phone after each push (about 30–60 seconds). Artifacts are another quick, private way to view a single-page app. Android APKs come from a GitHub Actions workflow that uploads the APK as an artifact (a ZIP). You download the ZIP in the phone browser, extract it, and install the APK.

### Cited Findings
**Simon Willison's GitHub Pages recipe (Jan 2026)**
1. Create a repo with a README.
2. Start a Claude Code for web task on it. You may need to restart the app so it sees the new repo.
3. Ask for "a self-contained HTML file in vanilla JavaScript with no build step," with dependencies loaded from a CDN.
4. When Claude creates its `claude/...` branch, go to repo **Settings → Pages**, keep "Deploy from a branch," and pick that branch.
5. After about a minute, the preview is live at `https://USER.github.io/REPO/index.html`.

Tips from the same post:
- Change requests, including screenshots, push to the same branch, so the preview updates.
- Switch Pages back to main after merging the PR.
- Pages has no artifact-style CSP, so the app can call outside APIs.
- Cloudflare Pages is an alternative for branch previews. — [Simon Willison TIL](https://til.simonwillison.net/claude-code/preview-github-pages)

**Simon Willison's Three.js game built entirely from the iPhone app (Aug 2026)**
- He told Claude to "Commit and push as often as possible so I can preview your work" and "Work independently - do not ask me to make any further design decisions."
- He asked for a `notes.md` build log, kept updated with every commit.
- Each push went live on Pages in about 30 seconds.
- Claude used Playwright with the pre-installed Chromium to screenshot the game at desktop and mobile widths.
- Bugs found only on real phones: the canvas rendered at double size, and an overlay blocked taps. Lesson: explicitly ask Claude to test mobile viewports and touch. — [Simon Willison, raccoon heist](https://simonwillison.net/2026/Aug/5/raccoon-heist/)

**David Wolgemuth's game built from his phone (Jan 2026)**
- He used a GitHub Action to deploy every PR to `/pr-preview/pr-N/` on GitHub Pages.
- Integration tests produced saved game states, which were encoded into the URL and posted as tappable "scenario" links in a PR comment.
- He added **eruda**, an in-page mobile devtools console, because mobile browsers have no DevTools.
- He kept a markdown backlog (`todos/README.md`) and started each session with "Look at the backlog, find a high priority item, work on it, mark it done in the PR."
- He kept PRs small and test-first. — [David Wolgemuth blog](https://david-wolgemuth.github.io/2026/01/01/vibe-coding-from-phone.html)

**GitHub Pages plan limits**
- GitHub Free includes "GitHub Pages in public repositories" only. Pages for private repos is a GitHub Pro feature.
- A private-access Pages site (one only logged-in members can view) requires an organization on Enterprise Cloud.
- Free includes $12/month of Actions compute and Pro includes $18. — [GitHub plans docs](https://docs.github.com/en/get-started/learning-about-github/githubs-plans)
- Willison notes a private repo's Pages URL is only "(secret)": anyone who guesses it can open it. — [Simon Willison TIL](https://til.simonwillison.net/claude-code/preview-github-pages); [raccoon heist](https://simonwillison.net/2026/Aug/5/raccoon-heist/)

**Artifacts**
- Artifacts are private by default and update in place as Claude republishes.
- The CSP blocks external images and non-CDN scripts, so games must inline assets or use data URIs, and the page must stay under 16 MiB.
- Downloads need a declared capability. — [Artifacts docs](https://code.claude.com/docs/en/artifacts)

**APKs from GitHub Actions**
- Typical workflow: run `./gradlew assembleDebug`, then `actions/upload-artifact`. — [DEV: automating APK builds](https://dev.to/ronynn/automating-android-apk-builds-with-github-actions-the-sane-way-1h95); [DEV: Ivan VC](https://dev.to/ivanvc/automating-building-android-apks-with-github-actions-150h)
- Downloading:
  - Open the run in the Actions tab and tap the file under **Artifacts**.
  - You must be logged in to GitHub to download artifacts.
  - On the phone, download the artifact and install it using a file manager app. — [Home Assistant: testing PR builds](https://developers.home-assistant.io/docs/android/tips/testing_pr_builds)
- An aggregator guide (Android phone-only flow) says the artifact arrives as a ZIP, which you can extract with an app like ZArchiver. This is a lower-quality source. — [search result: apk-builder-actions](https://sudo-self.github.io/apk-builder-actions/)
- Many APK templates assume a computer for the first clone. A phone-only user would instead have Claude create the workflow file in the repo. — [GitHub: android-apk-builder](https://github.com/wasishah33/android-apk-builder)

### Inferences
- Simplest path for a non-technical user making a small game: a single-file HTML5/JS game, previewed via a Pages branch (public repo on GitHub Free) or an artifact.
- Ask Claude to add a tiny on-screen debug log or eruda for on-phone debugging.
- For native Android, a more convenient alternative to downloading Actions artifacts may be having the workflow publish the APK as a **GitHub Release** asset, which is a direct link. This is my inference and no source covered it.
- Installing a downloaded APK requires allowing "install unknown apps" for the browser or file manager in Android settings. This is general Android knowledge, not sourced here.

### Gaps
- No official source confirms that the GitHub mobile app (as opposed to the mobile browser) can download Actions artifacts. Plan on using the browser at github.com.
- No sources found on building APKs inside a Claude cloud VM. That route depends on installing the Android SDK from allowed hosts; untested.

## 3. Tips for voice typing prompts, short messages, starting new sessions, and managing limits/credits on Pro/Max

### Takeaway
Use dictation (the app's microphone where available, otherwise the phone keyboard's voice typing) but re-read the transcript before sending, because coding agents follow instructions literally. Use short, standing prompts backed by files in the repo (backlog, notes). Use `/clear` or new sessions for new tasks to save context. Parallel cloud sessions burn shared limits faster.

### Cited Findings
**Voice**
- Coding agents follow instructions literally, so filler words or false starts in raw transcripts can turn into unintended instructions. Review dictated prompts before sending. — [AssemblyAI: voice coding](https://assemblyai.com/blog/voice-coding-dictate-to-coding-agents) (via search summary)
- Wispr Flow is a third-party system-wide dictation tool commonly paired with Claude Code on desktop. No source confirmed a mobile Claude Code setup. — [Zack Proser guide](https://zackproser.com/blog/wisprflow-claude-code-setup-guide); [Wispr Flow](https://wisprflow.ai/use-cases/claude)

**Prompting and project files**
- Use a reusable minimal prompt plus a markdown backlog and CONTRIBUTING.md in the repo, so prompts can stay "zero-thought." — [Wolgemuth](https://david-wolgemuth.github.io/2026/01/01/vibe-coding-from-phone.html)
- Put the up-front requirements in one first message: mobile/touch support, frequent pushes, autonomy, and a notes file. — [Willison raccoon heist](https://simonwillison.net/2026/Aug/5/raccoon-heist/)
- `CLAUDE.md` in the repo root is loaded by cloud sessions. A setup script can write personal preferences to `~/.claude/CLAUDE.md`. — [Cloud environments docs](https://code.claude.com/docs/en/cloud-environments)

**Managing context and sessions**
- `/compact` (optionally with focus text), `/context` and `/clear` work in cloud sessions. `/clear` "starts a fresh conversation with empty context in the same cloud session."
- Subagents keep the main conversation lighter. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)
- One session and PR can keep pushing changes for weeks; Willison found no session-length limit. — [Willison TIL](https://til.simonwillison.net/claude-code/preview-github-pages)
- Archive finished sessions to declutter the list. Archived sessions live at claude.ai/code/sessions under **Archived**. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)

**Usage limits**
- Cloud sessions "share rate limits with all other Claude and Claude Code usage," and running tasks in parallel "consumes more rate limits proportionately." — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)
- Pro and Max have a rolling 5-hour window plus a weekly cap. Max is roughly 5x Pro. The Max 20x plan was reportedly renamed Ultra on Oct 30, 2026. These come from third-party guides; verify on support.claude.com. — [DataCamp](https://www.datacamp.com/tutorial/claude-code-usage-limits); [Portkey](https://portkey.ai/blog/claude-code-limits)
- Official: weekly Claude Code limits were 50% higher from May 13 to Aug 31, 2026 (5-hour limits unchanged). That promotion is over. — [Claude Help Center](https://support.claude.com/en/articles/15910845-claude-code-may-july-2026-weekly-limits-promotion)
- In Mar–Apr 2026, users reported limits draining fast. Anthropic attributed this to peak-hour caps (weekdays 5–11am PT burned 5-hour limits faster) and ballooning contexts. Third-party reports say peak throttling was later removed for Pro and Max (May 2026); unverified. — [The Decoder](https://the-decoder.com/anthropic-says-claude-codes-usage-drain-comes-down-to-peak-hour-caps-and-ballooning-contexts/); [MacRumors](https://macrumors.com/2026/03/26/claude-code-users-rapid-rate-limit-drain-bug)
- Artifacts cost output tokens. Styled pages, and especially embedded images, are token-heavy. Prefer SVG/CSS and skip unneeded interactivity. — [Artifacts docs](https://code.claude.com/docs/en/artifacts)
- A reported mobile bug showed a stale "usage limit reached" message after a top-up while desktop worked. — [claudeissues.com #64455](https://claudeissues.com/issue/64455-mobile-stuck-on-stale-usage-limit-reached-reply-after-top-up-while-extra-usage-i)

### Inferences
- To stretch Pro limits, keep one task per session, `/clear` between unrelated tasks, avoid many parallel sessions, and use `/model` with a cheaper model for simple edits. The cost of `/model sonnet` is not documented in the sources.

### Gaps
- No official current table of Pro/Max/Ultra limits was retrieved. Third-party figures conflict.
- No Reddit-sourced voice-typing tips specific to Android were found.

## 4. Using GitHub from a phone (GitHub mobile app, PRs, Actions) alongside Claude Code

### Takeaway
Claude does most of the GitHub work itself: it commits, pushes, creates PRs and can watch PRs for CI failures. The user mainly needs the mobile browser for the repo settings Claude can't change (Pages source branch, Actions artifacts). The GitHub mobile app is good for reviewing and merging PRs and re-running workflows.

### Cited Findings
- **Auto-fix from the app:** tell Claude "watch this PR and fix any CI failures or review comments."
  - Requires the Claude GitHub App on the repo.
  - Auto-fix can't react to merge conflicts. Ask Claude to rebase. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)
- **PRs and diffs:** you can create a PR from the session, and the diff view supports inline comments. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)
- **Built-in GitHub tools:** the cloud VM has `gh` pre-installed, and GitHub operations go through a proxy that keeps your credentials off the VM. — [Cloud environments docs](https://code.claude.com/docs/en/cloud-environments)
- **GitHub Mobile:** it can re-run single jobs, failed jobs or entire workflows (2022), and has a debug toggle for re-runs (2023). — [GitHub changelog 2022](https://github.blog/changelog/2022-10-04-introducing-actions-on-github-mobile/); [GitHub changelog 2023](https://github.blog/changelog/2023-05-09-introducing-actions-on-the-repository-view-on-github-mobile)
- **Downloading artifacts:** official docs describe it via the web UI or `gh run download`. — [GitHub docs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts)
- **New repos:** Willison creates them at github.com/new and may need to restart the Claude app before the new repo shows up. — [Willison TIL](https://til.simonwillison.net/claude-code/preview-github-pages)

### Inferences
- Phone checklist:
  1. Create the repo in the browser.
  2. Start a Code session on it.
  3. Set the Pages branch in the browser.
  4. Review and merge PRs in the GitHub app or browser.
  5. Download APK artifacts in the browser.
- Use "desktop site" mode in the mobile browser if a settings page is hard to use. General knowledge, not sourced.

### Gaps
- No source confirmed whether the GitHub Android app can change Pages settings or download artifacts. Assume the browser is needed.

## 5. Known pain points and community workarounds

### Takeaway
The main pain points:
- You can't see or test the running app inside Claude Code on the phone.
- Mobile browsers have no devtools.
- The network allowlist blocks some downloads.
- Typing on a small screen is hard, and a long session list gets cluttered.
- Usage limits drain quickly.

Community workarounds:
- Branch or PR previews on GitHub Pages.
- Claude self-testing with headless Chrome/Playwright.
- In-page debug consoles (eruda).
- URL-encoded game states.
- Frequent commit/push.
- Repo-resident backlogs and notes.

### Cited Findings
- "it can be hard to test what it's working on while it's still working." Pages previews are the fix. — [Simon Willison TIL (via search summary)](https://til.simonwillison.net/claude-code/preview-github-pages)
- Coding on a phone means no local server or DevTools ("blind"). Workarounds: eruda and a custom debug log. — [Wolgemuth](https://david-wolgemuth.github.io/2026/01/01/vibe-coding-from-phone.html)
- **Network blocks:** in Limited mode, a domain that isn't allowlisted fails. Add the domain in the environment's **Allowed domains** list; existing sessions pick up the change within about a minute. — [Cloud environments docs](https://code.claude.com/docs/en/cloud-environments)
- **Session-list clutter:** critics said the Claude mobile app's auto-named sessions pile up with no search or rename. — [search summary of TNS/others](https://thenewstack.io/claude-code-usage-limits/)
- The `/rename <name>` command exists in cloud sessions. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)
- **Early iOS app bugs (Oct 2025):** keyboard freeze, rotation breakage, no image paste. Probably outdated. — [Every](https://every.to/vibe-check/vibe-check-we-spent-a-weekend-trying-to-code-from-our-phones)
- **Mobile-only rendering bugs:** device pixel ratio problems and overlay CSS blocking taps. Real-phone testing is required. — [Willison raccoon heist](https://simonwillison.net/2026/Aug/5/raccoon-heist/)
- **Computer-dependent alternatives:** Termux or Tailscale + SSH + tmux/Mosh, and apps such as Happy Coder and CC Pocket. All need a computer, so they are irrelevant for phone-only users. — [Harper Reed blog (Jan 2026)](https://harper.blog/2026/01/05/claude-code-is-better-on-your-phone/); [Builder.io (Mar 2026)](https://www.builder.io/blog/claude-code-mobile-phone)
- **Running Claude Code on the phone itself:** an unofficial Termux project does this, and its author notes there is no official Android build. Not recommended for non-technical users. — [ferrumclaudepilgrim/claude-code-android](https://github.com/ferrumclaudepilgrim/claude-code-android)
- **Exposed secrets:** sharing a session publicly (Pro/Max) can expose code or credentials. Check before sharing. — [Cloud docs](https://code.claude.com/docs/en/claude-code-on-the-web)

### Inferences
- Treat a phone-only build as small, single-page web games first. Native Android (APK) adds a GitHub Actions step and a download/install step, but needs no computer.

### Gaps
- Direct Reddit threads (r/ClaudeAI, r/ClaudeCode) were not retrieved. Community sentiment here comes via blogs and news summaries.
- Hacker News discussion was not reviewed in depth.
