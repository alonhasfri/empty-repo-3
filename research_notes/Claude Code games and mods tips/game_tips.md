# Practical tips for making browser games with Claude Code (phone-only, cloud sessions)

Context: the user drives Claude Code only from an Android phone (Code tab in the Claude app / claude.ai/code cloud sessions), plays results in a phone browser, and has limited weekly usage.

## 1. What workflows produce the best games (planning, CLAUDE.md, one feature at a time, prompts, game feel)?

### Takeaway
The best-documented phone-only workflow (Simon Willison, Aug 2026) is: create an empty GitHub repo, start a cloud session on it, ask for an `index.html` early, have Claude commit and push often, keep a running notes/progress log, and serve the branch with GitHub Pages so each push is playable on the phone ~30 seconds later. Quality comes from short iterations, one feature at a time, a short CLAUDE.md with project rules, and detailed descriptions of how things should look, feel and interact. A one-prompt build gives a working start, not a fun game.

### Cited Findings
- Simon Willison built a browser game entirely from his phone in a Claude Code web session: empty GitHub repo first, ask for `index.html` committed early, ask Claude to commit and push often, and keep a `notes.md` build log updated in every commit. — [Simon Willison, "Raccoon Heist"](https://simonwillison.net/2026/aug/5/raccoon-heist)
- His prompt style: short brief plus constraints (browser-only, static files, `index.html` entry point), explicitly require mobile support (touch controls, small screens), share reference images, name the tech or let Claude choose (it picked Three.js). — [Simon Willison](https://simonwillison.net/2026/aug/5/raccoon-heist)
- His result: a one-prompt build was a working starting point but shallow and easy to beat, and a planned "squad" mechanic was missing; rewriting the prompt produced a noticeably better design. — [Simon Willison](https://simonwillison.net/2026/aug/5/raccoon-heist)
- Cloud sessions run on Anthropic infrastructure and keep going after you close the app; you pick a repo and branch in the Code tab. Repository must be on GitHub. — [Claude Code docs: mobile](https://code.claude.com/docs/en/mobile); [Claude Code docs: cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web)
- In cloud sessions, `/compact`, `/context`, `/clear` work; `/model` and `/effort` take arguments (e.g. `/model sonnet`); commands like `/plugin` and `/resume` are not available. — [Claude Code docs: cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web)
- A roguelike developer's lessons: keep a CLAUDE.md with project structure, code patterns and never-violate rules plus a project tree; keep the project modular (small files, data-driven content); describe features in detail (function, appearance, key interactions; he used voice-to-text); require Claude to run tests before reporting back; expect to iterate most on UI and graphics, where the agent struggles most; agents tend to over-architect. — [Liminal Warmth, "Roguelike Vibecoding Tips"](https://liminalwarmth.substack.com/p/claude-code-context-lessons)
- Same source: if a branch gets tangled, discard and restart (cheap); keep architecture notes updated or the agent works from stale info. — [Liminal Warmth](https://liminalwarmth.substack.com/p/claude-code-context-lessons)
- A basic Breakout clone in Phaser 3 took a couple of hours in one session; features such as a multi-ball power-up were added incrementally in "quick little iterations"; author keeps prompts and transcripts in the repo. — [Les Orchard, Breakout with Claude](https://blog.lmorchard.com/2025/07/10/breakout-with-claude/index.md)
- The OpenAI-authored "develop-web-game" skill (republished for Claude Code in davila7/claude-code-templates) recommends: change one variable at a time, fix the first new console error before continuing, and keep `progress.md` with the original prompt at the top plus TODOs. — [vibehackers.io: develop-web-game](https://vibehackers.io/claude-code/skills/develop-web-game-davila7)
- Anthropic recommends plan mode for complex tasks, giving verification targets (expected output, screenshots), testing incrementally, and specific prompts over vague ones like "improve this". — [Claude Code docs: costs](https://code.claude.com/docs/en/costs)
- Keep CLAUDE.md under ~200 lines; it loads into every session. — [Claude Code docs: costs](https://code.claude.com/docs/en/costs)
- Phaser is a common choice for 2D browser games; Claude may hard-code a lot of values (ask for a config/constants object). — [Playgama blog](https://playgama.com/blog/business-faqs/how-to-use-claude-code-for-developing-browser-games-via-cli/)

### Inferences
- Good starter prompt template: "Make a [genre] game as a static site with `index.html` at the repo root. Must work on a phone in portrait: touch controls, scales to screen. No build step. Put all tunable numbers (speed, gravity, spawn rate) in one CONFIG object at the top. Commit and push when it runs. Keep notes.md updated."
- Describe game feel concretely: numbers and references ("jump feels like Celeste: quick rise, faster fall, coyote time 0.1s"), and ask for "juice" (screen shake, particles, hit pause, squash/stretch, sounds) as a separate step after the core loop works.
- Ask for a design doc (GDD.md) first in plan mode, approve it, then build one milestone per message.

### Gaps
- No rigorous comparison of prompting styles for "game feel"; advice is anecdotal.
- Did not find Reddit threads specific to phone-only Claude Code game making.

## 2. How do people make Claude test its own games?

### Takeaway
Cloud sessions include Chrome for Testing and Node, so Claude can run Playwright headlessly, screenshot the game at phone sizes, and read the images. The strongest patterns: expose game state on `window` (`render_game_to_text`), add a deterministic `advanceTime(ms)` hook, script full playthroughs, and test phone viewports with realistic device pixel ratios.

### Cited Findings
- Cloud sessions pre-install Node 20/21/22 (npm, chromedriver), Chrome for Testing at `/usr/bin/google-chrome` (`CHROME_PATH` set), Java 21 with Gradle, git and gh. — [Claude Code docs: cloud environments](https://code.claude.com/docs/en/cloud-environments)
- Willison had Claude use Playwright with the pre-installed Chromium to screenshot and inspect the game at desktop, portrait-phone and landscape-phone sizes; exposed state on `window` so scripts could teleport the player; scripted full playthroughs (pickups, enemy chases, win/lose, restart). Desktop-only tests missed a bug that appeared on real phones; test with realistic device pixel ratios. — [Simon Willison](https://simonwillison.net/2026/aug/5/raccoon-heist)
- develop-web-game skill: expose `window.render_game_to_text` returning concise JSON (player pos/velocity, enemies, collectibles, score, mode, coordinate system) and `window.advanceTime(ms)` for deterministic stepping; loop is implement, act, pause, observe, adjust; inspect latest screenshots; test multi-step chains end to end. — [vibehackers.io](https://vibehackers.io/claude-code/skills/develop-web-game-davila7)
- Canvas screenshot tests flake unless deterministic: seed RNG, freeze time, fix viewport, disable animations. — [skillselion: playwright-testing](https://skillselion.com/skills/chongdashu/phaserjs-oakwoods/playwright-testing)
- game-creator's QA runs five phases per step (build check, headless Chromium runtime check, gameplay replay, architecture validation, screenshot visual review) with an autofix subagent retrying up to 3 times. — [GitHub: OpusGameLabs/game-creator](https://github.com/OpusGameLabs/game-creator)
- Using strong tests at central "choke points" helped trace bugs far from their source. — [Liminal Warmth](https://liminalwarmth.substack.com/p/claude-code-context-lessons)

### Inferences
- Phone-friendly debug: ask for an on-screen debug overlay toggled by `?debug=1` in the URL (FPS, state, errors), since the user cannot open browser devtools on Android easily.
- Ask Claude to "screenshot at 390x844 with deviceScaleFactor 3 and look at it before telling me it's done."
- Testing costs usage; ask for it at milestones, not after every tiny tweak.

### Gaps
- No data on how many tokens a Playwright test loop consumes.

## 3. How to make games work well on phones?

### Takeaway
Set a proper viewport meta, size the canvas to the window times devicePixelRatio (capped ~2), add `touch-action: none` to stop pull-to-refresh, use a floating virtual joystick plus action button, handle resize/orientation, and save progress in localStorage. Check sprites and title art at multiple aspect ratios.

### Cited Findings
- Without `width=device-width` viewport, mobile browsers lay out at ~980px virtual width and scale down; size canvas from innerWidth/innerHeight × devicePixelRatio capped at 2; iOS address-bar collapse changes viewport height, so handle resize. — [Cinevva tutorial (2026, unverified)](https://app.cinevva.com/tutorials/mobile-friendly-web-games)
- `touch-action: none` on the canvas prevents pull-to-refresh/overscroll; add touch controls alongside keyboard controls. — [mobile-game-controls SKILL.md](https://raw.githubusercontent.com/trojan-lord/hermes-cuso/main/skills/mobile-game-controls/SKILL.md)
- MDN has a mobile touch controls tutorial (touch events / pointer handling). — [MDN: Mobile touch](https://developer.mozilla.org/en-US/docs/Games/Techniques/Control_mechanisms/Mobile_touch)
- Willison's mobile lessons: dynamic joystick that appears wherever you touch plus an action button; player sprite disappeared at small widths in one build; overwriting a canvas `style` string broke renderer sizing (2x on phones); a reused full-screen CSS class blocked taps; title art cropped differently across screen shapes. — [Simon Willison](https://simonwillison.net/2026/aug/5/raccoon-heist)
- Vendor libraries locally rather than CDN so the deployed game is self-contained. — [Simon Willison](https://simonwillison.net/2026/aug/5/raccoon-heist)
- Cloud environment default network allowlist includes npm registry but the documented list does not show CDNs like unpkg/jsdelivr in the excerpt checked. — [Claude Code docs: cloud environments](https://code.claude.com/docs/en/cloud-environments)
- A "web-games" community skill covers framework selection, WebGPU, optimization and PWA. — [tessl registry: web-games](https://tessl.io/registry/skills/github/popey/claude-code-skills/web-games)

### Inferences
- Install libraries with npm and copy the minified file into the repo (e.g. `lib/phaser.min.js`); this works in the sandbox and offline.
- Ask for: pause on `visibilitychange`, audio unlocked on first tap (browsers block autoplay), big tap targets, localStorage save with try/catch, and a manifest + service worker for "Add to Home screen" offline play.
- Prefer Canvas 2D or Phaser for low-end Android; Three.js is fine but keep polygon/particle counts low.

### Gaps
- Did not verify current Android Chrome behavior for fullscreen API/orientation lock from official docs.

## 4. Hosting/sharing for free from a phone, and turning it into an Android app

### Takeaway
GitHub Pages is the easiest: enable it once in repo Settings (doable in the phone browser), pick the Claude branch, and every push redeploys. itch.io accepts a single HTML file or a zip with index.html and has a "Mobile Friendly" switch. For an APK: Capacitor + a GitHub Actions workflow (Claude writes it, GitHub builds it, download the artifact on the phone), or PWABuilder/Bubblewrap TWA from the hosted URL.

### Cited Findings
- GitHub Pages: Settings, Pages, "Deploy from a branch", select the Claude branch; updates ~30s after each push; private repos work but the Pages site is visible to anyone who guesses the name. — [Simon Willison](https://simonwillison.net/2026/aug/5/raccoon-heist)
- Willison also suggested GitHub Pages and Cloudflare Pages as hosting options. — [neoteo summary of Willison](https://www.neoteo.com/en/simon-willison-built-four-claude-games-with-different-workflows)
- itch.io: single self-contained HTML file can be uploaded directly; otherwise ZIP with `index.html` at root, relative paths, max 1,000 files / 500 MB total / 200 MB per file; "Mobile Friendly" forces click-to-launch fullscreen on mobile; HTML5 games can only take donations; external resources must be HTTPS. — [itch.io docs: HTML5](https://itch.io/docs/creators/html5)
- Other distribution portals: Poki, CrazyGames, GameDistribution, Playgama, itch.io. — [Playgama blog](https://playgama.com/blog/business-faqs/how-to-use-claude-code-for-developing-browser-games-via-cli/)
- Capacitor generates an `android/` Gradle project; `npx cap sync android` then `./gradlew assembleDebug` outputs a debug APK in `app/build/outputs/apk/debug/`; release builds need JDK, Android SDK, keystore, `assembleRelease`; no Android Studio needed. — [Ionic forum](https://forum.ionicframework.com/t/how-to-build-an-android-apk-file-without-using-android-studio-in-a-capacitor-project/177814); [Capgo](https://capgo.app/blog/android-release-build-without-android-studio/)
- Prebuilt GitHub Action `action-capacitor-android` produces signed .aab and .apk; DEV write-up shows a workflow (setup Java+Node, decode keystore from secrets). — [GitHub: bytevictor/action-capacitor-android](https://github.com/bytevictor/action-capacitor-android); [DEV: Capacitor + GitHub Actions](https://dev.to/narottam04/seamlessly-convert-web-apps-to-android-app-automate-with-capacitor-and-github-actions-4e26)
- TWA (PWA in an Android app) requires `/.well-known/assetlinks.json` with the signing key's SHA-256; on GitHub Pages (Jekyll) you must add config so `.well-known` is published (or add `.nojekyll`). — [web.dev: Using a PWA in your Android app](https://web.dev/articles/using-a-pwa-in-your-android-app); [Chrome docs: Android concepts for web devs](https://developer.chrome.com/docs/android/trusted-web-activity/android-for-web-devs)
- Cloud VMs have Java 21 + Gradle but no Android SDK listed. — [Claude Code docs: cloud environments](https://code.claude.com/docs/en/cloud-environments)
- game-creator's deploy skill defaults to here.now and lists GitHub Pages, Vercel, Netlify, itch.io. — [GitHub: OpusGameLabs/game-creator](https://github.com/OpusGameLabs/game-creator)

### Inferences
- Phone-only APK path: ask Claude to add Capacitor + a `.github/workflows/android.yml` that builds a debug APK on push and uploads it as an artifact; download from the Actions run page in the phone browser and sideload (allow "install unknown apps"). Debug APK avoids keystore setup.
- Simplest "app" option: PWA manifest + service worker, then "Add to Home screen" in Chrome; no APK needed.

### Gaps
- PWABuilder docs did not load; could not confirm its current test-APK signing details.

## 5. Art, sound and music

### Takeaway
Kenney assets are CC0 (free, commercial use, no attribution needed). For sound, jsfxr/ZzFX generate retro SFX in code with no files; Web Audio can synthesize music. Paid/AI tools exist (game-creator's Retro Diffusion), and Willison gave Claude an image-generation API key for textures.

### Cited Findings
- Kenney assets are CC0 public domain; commercial use OK; attribution optional; don't use the Kenney logo separately. — [Kenney support](https://kenney.nl/support)
- jsfxr is an HTML5 port of sfxr usable as a JS library to generate and play sounds in game code. — [GitHub: chr15m/jsfxr](https://www.github.com/chr15m/jsfxr)
- ZzFX is a tiny MIT-licensed sound generator (20 parameters, no dependencies) aimed at prototyping and JS13K. — [npm: zzfx](https://npmjs.com/package/zzfx)
- game-creator uses Strudel.cc for music/SFX (games using `@strudel/web` must be AGPL-3.0 compatible) and `/retrodiffusion` for paid pixel art. — [GitHub: OpusGameLabs/game-creator](https://github.com/OpusGameLabs/game-creator)
- Willison gave Claude an image-generation API key for textures/title art, asked it to spot-check generated assets, and used prompts specifying style, lighting, mood plus "no text, no words, no logos". A texture can look right as a file but be applied wrongly in-game. — [Simon Willison](https://simonwillison.net/2026/aug/5/raccoon-heist)
- Asset creation can become the bottleneck once coding is fast. — [Liminal Warmth](https://liminalwarmth.substack.com/p/claude-code-context-lessons)

### Inferences
- Cheapest route: ask Claude to draw everything procedurally (shapes, gradients, emoji, SVG) first, then swap in Kenney packs. Kenney/OpenGameArt downloads may be blocked by the cloud sandbox's network allowlist; the user can upload files from the phone into the GitHub repo instead, or allow the domain in environment settings.
- OpenGameArt licenses vary per asset (CC0, CC-BY, GPL); ask Claude to keep a CREDITS.md.

### Gaps
- Did not verify OpenGameArt license details or whether kenney.nl is reachable from the default cloud allowlist.

## 6. Common pitfalls and how to avoid them

### Takeaway
Main pitfalls: huge single files Claude rewrites (costly and error-prone), regressions breaking working features, long sessions burning usage, and no undo. Use git as save points (commit every working state, experiments on branches), keep files modular, clear context between tasks, use Sonnet for routine work, and be specific.

### Cited Findings
- Git commits are save points; avoid "God commits" bundling many features; without git one person couldn't trace which of 12 changed files broke things. — [buildtolaunch](https://buildtolaunch.substack.com/i/194132798/skipping-version-control)
- Work on a separate experimental branch so the working app stays untouched; repeatedly asking AI about each new error can become a wasteful loop. — [search summary of vibe-coding mistakes articles](https://aimaker.substack.com/p/vibe-coding-mistakes)
- Duplicated logic and inconsistent naming accumulate after iterations; plan before building. — [Product Hunt discussion](https://www.producthunt.com/p/vibecoding/what-broke-first-when-you-tried-to-scale-a-vibe-coded-project)
- Usage: Claude Code sends the full conversation every request, so long sessions cost more; `/clear` between unrelated tasks (free), `/compact` with focus instructions (itself costly on big contexts); Sonnet for most coding, Opus for complex reasoning; lower `/effort`; Escape to stop wrong direction early; `/rewind` restores code and conversation to a checkpoint; first message after a long break misses cache and reprocesses everything; `/usage` shows plan usage. — [Claude Code docs: costs](https://code.claude.com/docs/en/costs)
- Cloud sessions share rate limits with all other Claude usage; parallel tasks consume proportionally more. — [Claude Code docs: cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web)
- Cloud sessions expire after inactivity; conversation is restored but running background work is not. — [Claude Code docs: cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web)
- Reports of 4x-10x token consumption variance on identical tasks and no real-time warning of a prompt's cost. — [levelup.gitconnected](https://levelup.gitconnected.com/claude-code-token-burn-the-unplanned-100-month-reality-48587c6a92ce) (anecdotal)
- One developer: $68 total for three Claude-built games including failed generations (anecdote). — search summary of [levelup.gitconnected](https://levelup.gitconnected.com/how-i-build-browser-games-with-ai-and-why-you-can-too-45e8efde5e22)

### Inferences
- Phone-friendly undo: "revert the last commit" or "go back to the version from commit X" in plain words; Claude does the git. Ask Claude to tag good versions (`v1-working`).
- Single-file HTML is great for sharing (itch.io accepts it) but past ~1,500 lines ask Claude to split into modules (no build step: ES modules) so edits stay small and cheap.
- Start a new session per feature, pointing at notes.md/CLAUDE.md, rather than one marathon session.

### Gaps
- No official per-plan token budget numbers for weekly limits were gathered.

## 7. Game-specific Claude Code skills/plugins

### Takeaway
OpusGameLabs/game-creator is the most complete game plugin (Phaser/Three.js, design, audio, QA, deploy, monetization), ~371 stars; it is heavyweight (multiple subagents per step, so usage-hungry) and built around npm/Vite and here.now/Play.fun. Lighter options: the develop-web-game skill (test loop) and community web-games skills. No independent quality reviews found.

### Cited Findings
- game-creator: install `npx skills add OpusGameLabs/game-creator -a claude-code` (README also shows `playableintelligence/game-creator`); commands `/make-game`, `/viral-game`, `/improve-game`, `/design-game`, `/add-feature`, `/add-assets`, `/add-audio`, `/qa-game`, `/review-game`, `/monetize-game`; code subagent + QA subagent after every code-changing step with autofix up to 3 attempts; 371 stars, 48 forks; MIT; needs Node/npm and system Chrome; mobile only mentioned for the threejs-3d template's touch input. — [GitHub: OpusGameLabs/game-creator](https://github.com/OpusGameLabs/game-creator); [claudemarketplaces](https://claudemarketplaces.com/skills/opusgamelabs/game-creator)
- Sources disagree on skill count (9 skills/8 commands/4 agents vs 26 skills). — [claudemarketplaces](https://claudemarketplaces.com/skills/opusgamelabs/game-creator); [GitHub](https://github.com/OpusGameLabs/game-creator)
- develop-web-game skill (author: openai, written for Codex, republished in davila7/claude-code-templates, MIT). — [vibehackers.io](https://vibehackers.io/claude-code/skills/develop-web-game-davila7)
- Other: popey/claude-code-skills web-games; chongdashu/phaserjs-oakwoods phaser-gamedev and playwright-testing skills. — [tessl](https://tessl.io/registry/skills/github/popey/claude-code-skills/web-games); [tomevault](https://tomevault.io/tome/chongdashu/phaserjs-oakwoods/phaser-gamedev)
- Skills can be committed to a repo's `.claude/skills`; cloud sessions load repo `.claude/agents/` automatically; `/plugin` isn't available in cloud sessions. — [Claude Code docs: cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web); [game-creator README](https://github.com/OpusGameLabs/game-creator)

### Inferences
- For a phone user with limited credits: ask Claude in the session to install a skill into the repo's `.claude/skills` and commit it (works without `/plugin`). Prefer single skills (e.g. game-designer, game-qa) over the full multi-agent pipeline to save usage.

### Gaps
- No independent reviews or benchmarks of game-creator quality or usage cost found.
