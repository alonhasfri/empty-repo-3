# Claude Code customizations ("mods") and workflow tips, with a cloud/mobile (Android, no terminal) lens

Research date: 2026-11-20. Most sources are the current Anthropic docs at code.claude.com (which reference Claude Code versions up to about v2.1.3xx), plus community lists and blogs. Community "best of" lists are unofficial and sometimes sponsored. Treat their rankings as opinion.

Legend used below:
- **[CLOUD OK]** works in a Claude Code cloud session that you drive from the Claude Android app.
- **[CLOUD: commit to repo]** works in cloud only if the file is committed to the repo (`.claude/...`, `CLAUDE.md`, `.mcp.json`).
- **[DESKTOP/TERMINAL ONLY]** matters only when Claude Code runs on your own computer, or uses terminal UI.

## Which plugins/skills/hooks are most recommended in 2025–2026 (official marketplace, community marketplaces, awesome lists)?

### Takeaway
Anthropic's official marketplace (`claude-plugins-official`) is the safest place to start. The most useful general-purpose plugins there are code-review, code-simplifier, feature-dev, commit-commands, hookify, claude-md-management, claude-code-setup, frontend-design, security-guidance, the output-style plugins, and the LSP "code intelligence" plugins. Community lists (hesreallyhim/awesome-claude-code above all) are best for hooks, status lines, and skills. However, **plugins do not install in cloud sessions from repo or user settings**. On mobile you mostly rely on what is committed to the repo (skills, agents, commands, hooks), on skills enabled on your claude.ai account, and on connectors.

### Cited Findings
**Official Anthropic marketplace**
- You install from the official marketplace with `/plugin install {plugin-name}@claude-plugins-official`. `/plugins` holds Anthropic-maintained plugins, and `/external_plugins` holds third-party plugins plus Anthropic's channel plugins (Discord, fakechat, iMessage, Telegram). New submissions go through claude.ai/directory/manage. Anthropic warns it does not control what MCP servers or files a plugin includes, so review a plugin before you install it — [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)
- Anthropic-internal plugins listed in the marketplace manifest — [marketplace.json](https://raw.githubusercontent.com/anthropics/claude-plugins-official/main/.claude-plugin/marketplace.json):
  - **claude-code-setup**: recommends hooks, skills, MCP servers and subagents for your repo
  - **claude-md-management**: audits and maintains CLAUDE.md files
  - **code-review**: multi-agent automated PR review
  - **code-simplifier**: simplifies recently modified code. Boris Cherny says he uses a code-simplifier subagent.
  - **commit-commands**: git commit, push and PR commands
  - **feature-dev**: feature workflow with exploration, design and review agents
  - **frontend-design**: production-grade frontend UI generation
  - **hookify**: creates hooks from conversation patterns or markdown rules
  - **explanatory-output-style** and **learning-output-style**: output styles that explain choices or teach
  - **claude-security**: deep vulnerability scanning with verified patches
  - **code-modernization**, **agent-sdk-dev**, **math-olympiad**, **math-proof**, **champion-kit**
- The same manifest lists LSP plugins (clangd, csharp, gopls, jdtls, kotlin, lua, liquid and others) and many vendor plugins, for example github, gitlab, linear, atlassian, figma, context7 (up-to-date library docs), firecrawl, exa (web search), chrome-devtools-mcp, browser-use, sentry-like observability tools (datadog, grafana, honeycomb), cloudflare, firebase, aws-*, and coderabbit/greptile (review) — [marketplace.json](https://raw.githubusercontent.com/anthropics/claude-plugins-official/main/.claude-plugin/marketplace.json). The manifest is only partly read (the list was truncated around "m"), so other plugins exist.
- Code intelligence (LSP) plugins give Claude precise symbol navigation ("go to definition") instead of grep plus reading many files. They also report type errors automatically after edits, which saves tokens — [Anthropic docs: Manage costs](https://code.claude.com/docs/en/costs)
- The hooks guide points to the **security-guidance** plugin as a production example of hooks that run a separate model review and feed findings back into the session — [Hooks guide](https://code.claude.com/docs/en/hooks-guide)
- Roundups frequently recommend feature-dev, frontend-design and security-guidance — [search summary of dev.to/composio/redwerk roundups](https://composio.dev/blog/top-claude-code-plugins). These are secondary and opinion-based.

**Bundled skills (built in, no install)**
- Bundled skills include `/doctor` (setup checkup), `/code-review`, `/batch`, `/debug`, `/loop`, `/claude-api`, `/simplify`, `/verify`, `/run`, `/run-skill-generator` and `/skill-doctor` — [Skills docs](https://code.claude.com/docs/en/skills)
- `/batch <change>` splits a big mechanical change into 5–30 units. Each unit gets its own worktree and opens a PR — [Best practices](https://code.claude.com/docs/en/best-practices)

**Community lists**
- hesreallyhim/awesome-claude-code is the most-cited list. A search summary reported about 36.8k stars. It covers skills, hooks, slash commands, agent orchestrators and plugins — [awesome-claude-code README](https://raw.githubusercontent.com/hesreallyhim/awesome-claude-code/HEAD/README.md); [claudefa.st overview](https://claudefa.st/blog/tools/resources/awesome-claude-code)
- Other lists: ComposioHQ/awesome-claude-plugins, rohitg00/awesome-claude-code-toolkit (claims 19 hooks, 150+ plugins, 135 agents), and disler/claude-code-hooks-mastery (hook examples written as uv single-file Python scripts) — [search results](https://github.com/ComposioHQ/awesome-claude-plugins)
- Notable entries in awesome-claude-code — [README](https://raw.githubusercontent.com/hesreallyhim/awesome-claude-code/HEAD/README.md):
  - Skills: anthropics/skills (the official SKILL.md format and examples); K-Dense scientific skills; Codex skill (call Codex from Claude); codebase-to-course
  - Status lines: ccstatusline, CCometixLine, Claude HUD, claude-powerline, claude-statusbar (rate-limit usage with reset countdown)
  - Notifications and sounds: Claudio (OS sounds through hooks), anotifier (desktop and phone push when Claude finishes or needs input)
  - Usage monitoring: Sidekick for Max, llm-router (routes prompts to the cheapest capable model)
  - CLAUDE.md: HumanLayer "Writing a good CLAUDE.md"; andrej-karpathy-skills drop-in CLAUDE.md

**What works on mobile/cloud**
- **[CLOUD: commit to repo]** A cloud session loads `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, `.claude/rules/` and `CLAUDE.md` from the clone. In a single-repo session it also loads `.claude/settings.json` hooks and permissions and `.mcp.json` MCP servers — [Cloud environments: What carries over](https://code.claude.com/docs/en/cloud-environments)
- **Not in cloud**: plugins and marketplaces declared in the repo's `.claude/settings.json` (`enabledPlugins` and `extraKnownMarketplaces` are not installed), plugins enabled only in user settings, `~/.claude/skills`, `~/.claude/agents`, `~/.claude/CLAUDE.md`, and MCP servers added with `claude mcp add` at local or user scope — [Cloud environments](https://code.claude.com/docs/en/cloud-environments)
- **[CLOUD OK]** Cloud sessions automatically load the skills you enable on your claude.ai account (claude.ai/customize/skills/yours) — [Skills docs](https://code.claude.com/docs/en/skills); [Cloud environments](https://code.claude.com/docs/en/cloud-environments)
- **[CLOUD OK]** In a cloud session Claude may show a plugin-suggestion card with an **Add** button. Tapping Add turns the plugin on for your claude.ai account, and it stays on after the session. You can turn suggestions off by denying the `SearchPlugins` and `SuggestPluginInstall` tools in `.claude/settings.json` — [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- `/plugin` and `/resume` are terminal-only commands and are not available in cloud sessions or the mobile app — [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web); [Mobile doc](https://code.claude.com/docs/en/mobile)

### Inferences
- For an Android-only user, the practical way to get a plugin's benefits is one of these:
  - Accept it through the in-session **Add** card, which enables it on your claude.ai account.
  - Copy the plugin's skills, agents or commands into the repo's `.claude/` folder and commit them.
  - Enable the equivalent skill on claude.ai.
- The docs disagree on one point. The "Add" card says the plugin is enabled for your claude.ai account, while the carry-over table says repo-declared and user-settings plugins don't load. Account-level (claude.ai) plugins are probably a separate path that does reach cloud sessions, but I didn't find an explicit statement that claude.ai-enabled plugins load in cloud sessions.
- Many popular community items (status lines, sound and notification hooks) are desktop-only.

### Gaps
- I found no authoritative popularity ranking (install counts) for official-marketplace plugins.
- I couldn't read the full marketplace manifest (it was truncated), so plugins after "m" (for example pr-review-toolkit, ralph-loop, security-guidance, playwright, sentry, slack) are unverified in this pass. security-guidance is confirmed only through the hooks guide reference.
- I didn't verify whether plugins enabled on claude.ai load in cloud sessions launched from the Android app.

## Which hook ideas are popular (auto-format, notifications, safety guards, auto-commit/backup, context/usage warnings, session summaries)?

### Takeaway
The canonical hooks are:
- a `Notification` hook for alerts
- `PostToolUse` auto-format after edits
- `PreToolUse` guards that block dangerous commands or protected files (exit code 2 blocks the call)
- a `Stop` hook that forces tests or typecheck to pass before Claude can finish
- `SessionStart` hooks to install dependencies or re-inject context after compaction
- `PreToolUse` output filters that save tokens

Hooks committed to the repo's `.claude/settings.json` do run in single-repo cloud sessions. Desktop-notification and sound hooks are useless on a phone-only cloud setup.

### Cited Findings
- Official example use cases — [Hooks guide](https://code.claude.com/docs/en/hooks-guide):
  - get notified when Claude needs input (`Notification` event)
  - auto-format code after edits (`PostToolUse`)
  - block edits to protected files (a `protect-files.sh` script on `PreToolUse`)
  - re-inject context after compaction (`SessionStart` with the `compact` matcher)
  - audit configuration changes (`ConfigChange`)
  - reload the environment when the directory or files change
  - auto-approve specific permission prompts (`PermissionRequest`)
- Hook types are `command`, `prompt` (a model judges), `agent`, and `http` — [Hooks guide](https://code.claude.com/docs/en/hooks-guide)
- A `PreToolUse` hook that returns `deny` blocks the tool even in bypassPermissions mode or with `--dangerously-skip-permissions`. A hook that returns `allow` cannot override deny rules — [Hooks guide](https://code.claude.com/docs/en/hooks-guide)
- Timeouts: command, http and mcp_tool hooks get 10 minutes. UserPromptSubmit hooks get 30 seconds, prompt hooks 30 seconds, and agent hooks 60 seconds. SessionEnd hooks share a 1.5-second budget, which can be raised up to 60 seconds. `Stop` hooks fire whenever Claude finishes responding, not only when the task is complete — [Hooks guide](https://code.claude.com/docs/en/hooks-guide)
- Stop-hook gate example: `"Stop": [{"hooks":[{"type":"command","command":"pnpm tsc --noEmit 1>&2 || exit 2"}]}]`. Exit 2 blocks the stop and stderr goes back to Claude. After 8 consecutive blocks Claude Code overrides the hook; `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` raises that cap — [Best practices](https://code.claude.com/docs/en/best-practices)
- Best-practices guidance: a CLAUDE.md line like "Always typecheck" works "most of the time, not every time". Rules that can't have exceptions belong in hooks or deny rules — [Best practices](https://code.claude.com/docs/en/best-practices)
- Token-saving hook: Anthropic's example `PreToolUse` hook rewrites `npm test`/`pytest`/`go test` to pipe through `tail -n 100`. More generally, a hook can grep a 10,000-line log for ERROR, "reducing context from tens of thousands of tokens to hundreds" — [Costs doc](https://code.claude.com/docs/en/costs)
- Boris Cherny uses a `PostToolUse` hook to format code and catch formatting issues before CI. He also routes permission requests to Opus through a hook, which scans them for attacks and auto-approves safe ones — [Boris tips notes (Jan 31 2026 thread)](https://snowan.gitbook.io/study-notes/ai/claude-code/boris-cherny-cc-tips); original [X thread](https://x.com/bcherny/status/2017742741636321619)
- Community safety guards:
  - regex `PreToolUse` blockers for `rm -rf`, credential reads and `git push --force` — [gist](https://gist.github.com/Mandalorian007/3dcafac5b8e97458bdc8816ce0d4f55d)
  - cc-safe-setup, which blocks rm on `/`, `~`, `.git`, `.ssh`, `.env` — [cc-safe-setup](https://yurukusa.github.io/cc-safe-setup/prevent-rm-rf.html)
  - Caveat: regexes miss variants such as `rm -fR` and chained commands — [dev.to bash-guard](https://dev.to/boucle2026/bash-guard-stop-claude-code-from-running-dangerous-commands-95g)
- Notification and sound hooks from the community: Claudio (OS sounds), anotifier (desktop toast plus phone push), tmux-claude-status-tabs — [awesome-claude-code](https://raw.githubusercontent.com/hesreallyhim/awesome-claude-code/HEAD/README.md)
- **Cloud specifics**:
  - Repo `.claude/settings.json` hooks run in single-repo cloud sessions. They do not run in multi-repo sessions or in project cloud threads.
  - User-level `~/.claude/settings.json` hooks don't reach the cloud.
  - Hooks run both locally and in the cloud. Gate cloud-only logic on `CLAUDE_CODE_REMOTE=true`.
  - SessionStart hooks run on every start and resume, so keep them idempotent and fast.
  - Source: [Cloud environments](https://code.claude.com/docs/en/cloud-environments)

### Inferences
- **Best hooks for a phone-only cloud user**, committed in `.claude/settings.json`:
  1. a SessionStart dependency install gated on `CLAUDE_CODE_REMOTE`
  2. a PostToolUse formatter
  3. a Stop hook running tests or typecheck
  4. a PreToolUse dangerous-command guard
  5. a SessionStart `compact` matcher that re-injects key rules
  6. a PreToolUse output trimmer to save usage
- Cloud VMs are disposable and work lands on `claude/` branches, so auto-commit and backup hooks matter less there. Pushing to a branch is effectively the backup.
- **Desktop/terminal only**: Notification-to-desktop hooks, sound hooks, and tmux status-tab hooks.

### Gaps
- I found no reliable data on how widely each hook idea is used. The "popularity" is inferred from how often guides and lists repeat them.
- I didn't find an official "session summary" hook example. The community does this with Stop or SessionEnd hooks, but I didn't verify a specific project.

## Tips from Anthropic staff (Boris Cherny etc.) and power users: plan mode, CLAUDE.md, subagents, /compact, /clear, checkpoints/rewind, usage

### Takeaway
Boris Cherny's Jan 31, 2026 thread, combined with Anthropic's current best-practices doc, comes down to six habits:
- Plan first (plan mode) on complex tasks.
- Keep CLAUDE.md short. Update it after every correction, and keep it under about 200 lines.
- Turn repeated workflows into skills or commands and commit them.
- Give Claude a way to verify its work (tests, Stop hook, review subagent).
- Run sessions in parallel (worktrees or cloud sessions).
- Use `/clear` between tasks, steer early with Esc and `/rewind`, and start fresh after two failed corrections.

### Cited Findings
- **Boris Cherny thread** (X, Jan 31 2026) — [notes](https://snowan.gitbook.io/study-notes/ai/claude-code/boris-cherny-cc-tips); [original](https://x.com/bcherny/status/2017742741636321619):
  - Run 3–5 git worktrees, each with its own Claude session. Start complex tasks in plan mode (Shift+Tab) and invest in the plan so implementation is one pass. Some teammates have a second Claude review the plan "as a staff engineer".
  - After each correction, end with "Update your CLAUDE.md so you don't make that mistake again". One engineer keeps a per-project notes directory that CLAUDE.md points to.
  - Anything you do more than once a day should become a skill or command committed to git. Team examples: `/techdebt`, a context-dump command that syncs 7 days of Slack/Drive/Asana/GitHub, and dbt agents.
  - Let Claude fix bugs on its own: paste a Slack bug thread and say "fix", or "fix the failing CI tests".
  - Prompting: have Claude grill you or prove the change works by diffing against main. After a mediocre fix, ask it to "scrap this and implement the elegant solution".
  - Say "use subagents" to throw more compute at a problem.
  - Use `/statusline` to show context usage and git branch (terminal), and voice dictation.
  - Use the Explanatory or Learning output style to learn. Ask for ASCII diagrams or HTML explainers.
- Secondary write-ups give varying tip counts (10, 13, 22). Treat them as secondary — [search results](https://medium.com/@joe.njenga/boris-cherny-claude-code-creator-shares-these-22-tips-youre-probably-using-it-wrong-1b570aedefbe)
- **CLAUDE.md (official)** — [Best practices](https://code.claude.com/docs/en/best-practices):
  - Include only what Claude can't infer from the code: exact test, typecheck and lint commands; misleading code areas; decisions not recorded in the repo; anything you've corrected twice.
  - `/init` generates a draft. `/doctor` suggests cuts, and `/doctor prompt-audit` flags stale or contradictory instructions. Keep the file under 200 lines.
  - Put personal preferences in `CLAUDE.local.md` (gitignored).
  - Don't describe the architecture or file layout. Adding IMPORTANT or ALL CAPS is outdated advice; turn a hard rule into a hook instead.
- Move workflow-specific instructions out of CLAUDE.md into skills. A skill body loads only when used, while CLAUDE.md loads every session — [Costs](https://code.claude.com/docs/en/costs); [Skills](https://code.claude.com/docs/en/skills)
- **Steering** — [Best practices](https://code.claude.com/docs/en/best-practices):
  - Esc stops Claude mid-action. `/rewind` (or Esc twice) rolls back code, conversation or both.
  - Checkpoints cover only edits made with Claude's file tools. Bash-made changes aren't restored, so keep using git.
  - After two failed corrections, `/clear` and write a better prompt.
  - `/btw` asks a side question without adding to history. `/rename` plus `claude --resume name` resumes a session later (terminal).
- **"What you can stop doing"** (official, 2026) — [Best practices](https://code.claude.com/docs/en/best-practices):
  - Current models have a 1M-token window with auto-compaction, so aggressive context management matters less. `/clear` is still worth using for focus and cost.
  - "think hard" phrases don't raise effort; use `/effort`. `ultrathink` still asks for deeper reasoning on a single turn.
  - Subagents don't produce better answers on their own, but they are useful for parallel work, keeping noisy output away, and fresh-eyes review.
  - Note: a lot of 2025-era advice (context-window anxiety, CAPS emphasis, "think harder") is now officially considered outdated.
- **Verification**: give Claude a check to run (tests, screenshots, expected output). Use a second session as an independent reviewer — [Best practices](https://code.claude.com/docs/en/best-practices)
- **Unattended runs** (five questions): does it know what "done" looks like, can it check its work, what may it touch, what stops it (`--max-turns`, `--max-budget-usd`), and who signs off — [Best practices](https://code.claude.com/docs/en/best-practices)
- **In cloud sessions**:
  - `/compact` (with optional focus text), `/context` and `/clear` all work.
  - Cloud sessions set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` themselves, so compaction triggers early.
  - Subagents in `.claude/agents/` load automatically.
  - Agent teams need `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` as an environment variable.
  - `/model`, `/effort`, `/color` and `/rename` take arguments instead of opening pickers, for example `/model sonnet`.
  - Source: [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- Plan mode is available in cloud sessions from the app. The permission modes there are Accept edits, Plan and Auto; Bypass is not available from the app — [Mobile doc](https://code.claude.com/docs/en/mobile)
- Rewind is available in cloud sessions too. The doc troubleshoots "Rewind to here" in cloud (on self-hosted runners) — [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- Official tip: "Plan locally, execute in the cloud". Save the plan to the repo, push, then `claude --cloud "Execute the plan in docs/plan.md"` — [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)

### Inferences
- On Android: use Plan mode from the mode dropdown first, then switch to Accept edits or Auto. To make CLAUDE.md updates permanent, ask Claude to edit the repo `CLAUDE.md` and push, because the cloud VM is thrown away.
- **Desktop/terminal-only Boris tips**: Ghostty, tmux, tab colors, `/statusline`, voice dictation with fn-fn, and shell aliases for worktrees. Running parallel sessions maps to several cloud sessions on mobile.

### Gaps
- I couldn't fetch the original X thread directly (it was cited through a secondary note). Boris's other threads (e.g., a Dec 2025/Jan 2026 "how I use Claude Code" setup thread) were referenced by secondary sources but not verified.

## What works specifically in Claude Code on the web / cloud sessions (setup scripts, environments, SessionStart hooks, connectors, scheduled tasks, artifacts, remote control, notifications)

### Takeaway
A cloud session is a fresh clone in an Anthropic VM. Only what's committed to the repo, what's configured on the cloud **environment** (network, environment variables, network secrets, setup script), what's enabled on your **claude.ai account** (skills, connectors), and server-managed settings reach it. The Android app is a full client for cloud sessions, projects, Remote Control and scheduled tasks, but terminal-only commands such as `/plugin` and `/resume` don't work there.

### Cited Findings
- **Where you can start cloud sessions**: claude.ai/code, the **Code** tab in the Claude Android/iOS app, the Desktop app, `claude --cloud`, and cloud scheduled tasks. Plans: Pro, Max, Ultra, Team, and Enterprise premium seats. Cloud sessions count toward your plan usage, with no separate VM charge — [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- **The mobile app is a client only.** Its Code tab offers:
  - cloud sessions (your GitHub repo; keeps running with the phone off)
  - projects (coordinated parallel threads)
  - Remote Control (drives a session on your own computer, which must stay on)
  - Dispatch (Pro, Max or Ultra; drives the Desktop app)
  - Source: [Mobile doc](https://code.claude.com/docs/en/mobile)
- **Environments** — [Cloud environments](https://code.claude.com/docs/en/cloud-environments):
  - Each environment has a network level: None, Limited (the default, with package managers allowed) or Full. You can also allow specific domains.
  - Environments hold environment variables (readable by anyone who uses the environment, so no secrets there) and network secrets. A network secret is injected by the proxy, and the session never sees it.
  - Each environment also has a setup script.
  - Connector traffic bypasses the allowlist because it goes through Anthropic's servers.
- **Setup scripts** — [Cloud environments](https://code.claude.com/docs/en/cloud-environments):
  - A setup script is a Bash script that runs before Claude starts.
  - If it finishes in about 5 minutes or less, the filesystem is snapshotted and cached for later sessions. The cache rebuilds when the script or network changes, and roughly every 7 days.
  - Background processes aren't cached; start those with a SessionStart hook.
  - A setup script can write `~/.claude/CLAUDE.md` for personal cloud-only instructions. Check it loaded with `/context`.
- **Setup script vs SessionStart hook** — [Cloud environments](https://code.claude.com/docs/en/cloud-environments):
  - Use the setup script to provision the VM (toolchains).
  - Use a SessionStart hook committed to the repo for project setup such as `npm install`. It runs on every start and resume, both local and cloud; gate it with `CLAUDE_CODE_REMOTE`.
  - The hook doesn't run in multi-repo sessions or project threads.
- **Pre-installed tools**: Python (uv, ruff, pytest), Node 20–22 (pnpm, bun, eslint, prettier), Ruby, PHP, Java, Go, Rust, C/C++, Docker, PostgreSQL 16, Redis 7, Chrome for Testing, gh, jq, ripgrep and tmux. Ask Claude to run `check-tools` to see versions — [Cloud environments](https://code.claude.com/docs/en/cloud-environments)
- **Time limits**: Bash commands default to 2 minutes and can go up to 10. A command that hits its timeout moves to the background for up to 30 more minutes. Set `BASH_DEFAULT_TIMEOUT_MS` / `BASH_MAX_TIMEOUT_MS` as environment variables to change this — [Cloud environments](https://code.claude.com/docs/en/cloud-environments)
- **Settings**:
  - Cloud sessions read the committed `.claude/settings.json` (single repo) and server-managed settings only. They don't read `~/.claude/settings.json` or `settings.local.json`.
  - `/config` opens the claude.ai settings page. To change a setting, set an environment variable on the environment or commit it to `.claude/settings.json`.
  - Source: [Settings doc](https://code.claude.com/docs/en/settings)
- **Connectors**:
  - Connectors are your claude.ai integrations (Gmail, Drive, Slack, Linear and so on). They are included in scheduled tasks by default.
  - MCP servers added with `claude mcp add` locally don't appear in cloud. Add them at claude.ai/customize/connectors, or commit `.mcp.json` with `--scope project`.
  - A session counts as inactive while waiting for you to approve a connector tool call, so it can expire during that wait.
  - Sources: [Scheduled tasks doc](https://code.claude.com/docs/en/routines); [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- **Cloud scheduled tasks** (formerly "routines", research preview) — [Scheduled tasks doc](https://code.claude.com/docs/en/routines):
  - A saved prompt, plus repos, plus connectors, run in the cloud.
  - Triggers: Schedule (hourly at most; custom cron; one-off runs), API (POST with a bearer token), and GitHub events (needs the Claude GitHub App).
  - Create at claude.ai/code/routines, in the Desktop app, or with `/schedule` (alias `/routines`), for example `/schedule daily PR review at 9am`.
  - Runs use subscription usage. Limits: 100 scheduled runs per hour per account; 30 per hour per task for Run now and API fires.
  - Runs push to `claude/` branches. Protect `main` with branch rules.
  - Skills must be enabled on claude.ai or committed to the repo; local `~/.claude/skills` gives "skill not found".
- **Session-scoped scheduling**: `/loop 15m <prompt>` repeats a prompt inside a session. Each run is another turn that sends the full context, so it costs usage. These tasks don't survive VM expiry — [Best practices](https://code.claude.com/docs/en/best-practices); [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- **Auto-fix PRs**: from the mobile app, tell Claude "watch this PR and fix any CI failures or review comments". This needs the Claude GitHub App. Claude pushes clear fixes and asks about ambiguous ones — [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- **Push notifications**: when Remote Control is active, Claude can send push notifications to your phone when a task finishes or needs a decision. You can also ask in your prompt, for example "notify me when the tests finish". Two `/config` toggles control this — [Mobile doc](https://code.claude.com/docs/en/mobile)
- **Moving between devices**:
  - `claude --teleport` / `/teleport` pulls a cloud session to a terminal (one-way).
  - `claude -p "msg" --cloud <id>` queues a follow-up from any CLI.
  - Sessions persist across devices, and you can answer an idle session's question later, until the environment expires.
  - When the environment expires, conversation history is restored but background shells, subagents and loops are not.
  - Source: [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- **Sharing**: Pro and Max users can set a session Private or Public; Team users can set it Team-visible. Check for secrets before sharing — [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- **Diff review on phone**: the Changes card shows +/- counts. You can comment on lines in the diff view and send the comments to Claude — [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- **Session transcript link**: `CLAUDE_CODE_REMOTE_SESSION_ID` gives a traceable link you can put in PR bodies — [Cloud environments](https://code.claude.com/docs/en/cloud-environments)
- **Artifacts**: `enableArtifact` / `disableArtifact` settings exist and control the Artifact tool (v2.1.242+) — [Settings doc](https://code.claude.com/docs/en/settings). (Not researched in depth; see the artifacts doc link referenced there.)

### Inferences
- **Mobile "mods" checklist**:
  1. Commit `CLAUDE.md`, `.claude/settings.json` (hooks and permission deny rules), `.claude/skills`, `.claude/agents`, `.claude/commands` and `.mcp.json`.
  2. Create a personal environment with a setup script that installs your toolchain and writes `~/.claude/CLAUDE.md` with personal preferences.
  3. Put API keys in network secrets.
  4. Enable your skills and connectors on claude.ai.
  5. Use scheduled tasks for recurring jobs.
  6. Use auto-fix for PRs.
- **Terminal/desktop-only items**: status lines (`/statusline`, ccstatusline and similar), themes, keybindings (`~/.claude/keybindings.json`), vim/editor mode, spinner tips, terminal or OS notification and sound hooks, `/plugin` management, `/resume`, user-scope `~/.claude/*` config, local `claude mcp add` servers, `.worktreeinclude`, and the `/usage` interactive "f to fix" screen. Remote Control and Dispatch need your own computer to be running.

### Gaps
- I didn't capture the exact names of the two `/config` push-notification toggles for Remote Control. It's also unclear whether push notifications fire for pure cloud sessions, as opposed to Remote Control sessions.
- I didn't verify how artifacts are created or viewed from a cloud session on Android.

## Ways to reduce usage/credit consumption

### Takeaway
The biggest wins:
- `/clear` between unrelated tasks (free).
- Use Sonnet, or a lower `/effort`, for routine work.
- Keep CLAUDE.md short and move procedures into on-demand skills.
- Prefer CLI tools over MCP servers.
- Trim tool output with hooks.
- Give specific prompts and plan first to avoid rework.
- Watch background consumers (`/loop`, scheduled tasks, subagents, agent teams, idle compaction).
- Avoid returning to a stale session after the cache expires.

### Cited Findings
- `/usage` on subscription plans breaks usage down by skill, subagent, plugin and MCP server. It recommends fixes for anything above 10% of usage, and `f` applies them (v2.1.305+). `/insights` writes an HTML report on your work patterns — [Costs doc](https://code.claude.com/docs/en/costs)
- `/clear` between tasks; stale context "wastes tokens on every subsequent message". `/compact <focus>` keeps what matters, but compacting a large context is itself a big request. You can add a "# Compact instructions" section to CLAUDE.md — [Costs doc](https://code.claude.com/docs/en/costs)
- **Model choice**: Sonnet handles most coding. Reserve Opus for complex reasoning. Set `model: haiku` for simple subagents. Switching model mid-session loses the prompt cache for the first request — [Costs doc](https://code.claude.com/docs/en/costs); [Settings doc](https://code.claude.com/docs/en/settings)
- **Thinking**: lower effort with `/effort`. Thinking is billed as output, and the default budget can be tens of thousands of tokens. `MAX_THINKING_TOKENS` applies only to fixed-budget models. Thinking can't be turned off on Opus/Sonnet/Haiku 5.5 — [Costs doc](https://code.claude.com/docs/en/costs)
- **MCP**: tool definitions are deferred by default. Still, prefer CLIs (gh, aws, gcloud) and disable unused servers with `/mcp` — [Costs doc](https://code.claude.com/docs/en/costs)
- Keep CLAUDE.md under 200 lines and move workflow instructions into skills. Skill bodies load only on use but then stay in context. Keep SKILL.md under 500 lines and put the bulk in supporting files — [Costs doc](https://code.claude.com/docs/en/costs); [Skills doc](https://code.claude.com/docs/en/skills)
- **Agent teams** use about 7x the tokens when teammates run in plan mode. Keep teams small and use Sonnet for teammates — [Costs doc](https://code.claude.com/docs/en/costs)
- **Why usage climbs in long sessions** — [Costs doc](https://code.claude.com/docs/en/costs):
  - The full history is sent on every request.
  - A cache miss after a break re-processes everything.
  - Scheduled tasks and `/loop` fire while you're idle.
  - Cross-session messages and goal check-ins add turns.
  - Subagents send their own requests.
- **Prompt cache lifetime**: about 1 hour on a subscription; 5 minutes on an API key or usage credits (and for subagents). An idle session past about 200K tokens is compacted shortly before the cache expires. "If you don't need the history at all, a fresh session still costs less" — [Best practices](https://code.claude.com/docs/en/best-practices)
- Background token use also comes from session recap, idle compaction and prompt suggestions, and each can be turned off — [Costs doc](https://code.claude.com/docs/en/costs)
- **Cloud sessions** share rate limits with all Claude usage. Parallel cloud tasks consume limits proportionately — [Cloud sessions doc](https://code.claude.com/docs/en/claude-code-on-the-web)
- **Limits**: subscription limits are a 5-hour rolling window plus a weekly window, shared with Claude chat. Usage credits (`/usage-credits`) let you continue past the limit, and you can set a monthly spend cap. Claude Code v2.1.234+ can wait for the reset and then continue automatically — [Costs doc](https://code.claude.com/docs/en/costs)
- **Prompting**: specific prompts ("add input validation to login in auth.ts") avoid broad scans. Plan mode, early Esc and `/rewind` prevent expensive rework — [Costs doc](https://code.claude.com/docs/en/costs)
- **Community tools**: claude-statusbar / ccstatusline show rate-limit usage (terminal only); llm-router sends prompts to the cheapest capable model — [awesome-claude-code](https://raw.githubusercontent.com/hesreallyhim/awesome-claude-code/HEAD/README.md)

### Inferences
- **Mobile-specific savings**:
  - Start a new cloud session per task instead of reusing a long one.
  - Use `/model sonnet` and `/effort` with arguments.
  - Remove unneeded connectors from scheduled tasks.
  - Don't leave a `/loop` running in a long session.
  - Prefer one well-planned session over many parallel ones when you're near your limits.
- The `/usage` interactive breakdown is described for the CLI, and its local-history figures exclude claude.ai usage. On Android, check claude.ai/settings/usage instead.

### Gaps
- I found no official per-plan token quotas; Anthropic doesn't publish exact numbers.
- ccusage, a popular local usage analyzer, didn't come up in the searches I ran, so it's not cited here. It's terminal-only in any case.
