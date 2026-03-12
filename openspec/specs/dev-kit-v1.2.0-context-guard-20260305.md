# SDD: dev-kit v1.2.0 — Context Guard + Skills Catalog

## Context
dev-kit v1.1.0 shipped 52 skills but lacks two critical features for standalone users (vibe coders without Jefest):
1. **Skills catalog** — no overview doc listing all skills with categories and usage guide
2. **Context/session management** — no tools to monitor context usage, save session state, or rotate sessions

These exist in Jefest but depend on RLM and Jefest infra. This SDD creates standalone, RLM-free versions for dev-kit.

## Environment
- Project: 1c-ai-development-kit, path: C:\Users\Arman\workspace\public\1c-ai-development-kit
- Skills: powershell-windows, workflow-automation, python-patterns

## Compatibility
- OS: win32
- Platform: powershell + claude-code
- Required tools: Bash, Read, Write, Edit
- Profile: balanced

## Approach
Three work streams:
1. **SKILLS.md** — auto-generated catalog from existing SKILL.md files, organized by category with descriptions. Includes global (11) + project (52) = 63 total skills listed with aliases mapping.
2. **Context monitor** — portable `context-monitor.ps1` (already clean, 17 lines) + hook config in settings.json
3. **Session management skills** — 3 new skills replacing RLM-dependent Jefest rituals with local file-based storage (`session-notes.md`)

No RLM dependency. No Jefest paths. No IP addresses. All self-contained.

## Files
- `SKILLS.md` — NEW — Public skills catalog with categories, descriptions, usage guide
- `scripts/context-monitor.ps1` — NEW — PostToolUse hook: counts tokens, warns at 70%/85%
- `scripts/rotate-session.ps1` — NEW — Opens new terminal tab with fresh Claude session
- `.claude/skills/session-save/SKILL.md` — NEW — Save session state to local `session-notes.md`
- `.claude/skills/session-restore/SKILL.md` — NEW — Restore session state from `session-notes.md`
- `.claude/skills/session-retro/SKILL.md` — NEW — Session retrospective (what worked, what didn't)
- `docs/guides/session-management.md` — NEW — Setup guide: hooks, workflow, examples
- `.claude/settings.local.json` — EDIT — Add context-monitor as PostToolUse hook

## Atomic Tasks

1. Create worktree: `git worktree add .worktrees/dispatch-v1.2.0 -b dispatch/v1.2.0`
2. cd `.worktrees/dispatch-v1.2.0`

### Skills Catalog (SKILLS.md)

3. Generate `SKILLS.md` in project root:
   - Scan `.claude/skills/*/SKILL.md` — extract skill name (dir name) and first line of description
   - Also scan global skills list (hardcoded: api-expert, code-review, docker-expert, playwright-skill, postgres-expert, powershell-windows, python-patterns, security-audit, testing-patterns, visual-explainer, workflow-automation)
   - Organize into categories:
     ```
     ## Global Skills (11)
     Infrastructure, API, testing, code review — work across all project types.

     ## 1C — Configuration (4): cf-init, cf-edit, cf-info, cf-validate
     ## 1C — Metadata (5): meta-compile, meta-edit, meta-info, meta-remove, meta-validate
     ## 1C — Database (9): db-create, db-list, db-load-git, db-load-xml, db-load-cf, db-dump-xml, db-dump-cf, db-update, db-run
     ## 1C — Extensions (5): cfe-init, cfe-borrow, cfe-patch-method, cfe-diff, cfe-validate
     ## 1C — Forms (7): form-compile, form-edit, form-add, form-info, form-patterns, form-remove, form-validate
     ## 1C — EPF/ERF (7+4): epf-init, epf-build, epf-dump, epf-add-form, epf-bsp-init, epf-bsp-add-command, epf-validate + erf-init, erf-build, erf-dump, erf-validate
     ## 1C — MXL/Templates (5): mxl-compile, mxl-decompile, mxl-info, mxl-validate, template-add, template-remove
     ## 1C — DCS/SKD (4): skd-compile, skd-edit, skd-info, skd-validate
     ## 1C — Subsystems/Roles (7): subsystem-compile, subsystem-edit, subsystem-info, subsystem-validate, interface-edit, interface-validate, role-compile, role-info, role-validate
     ## 1C — Web/Testing (6): web-publish, web-info, web-stop, web-unpublish, web-test, 1c-web-session, 1c-test-runner, playwright-test
     ## 1C — Knowledge/Planning (10): 1c-help-mcp, 1c-query-opt, bsp-patterns, 1c-project-init, brainstorm, write-plan, openspec-proposal, openspec-apply, openspec-archive, subagent-dev, help-add, img-grid
     ## Session Management (3) [NEW in v1.2.0]: session-save, session-restore, session-retro
     ```
   - For each skill: `| skill-name | one-line description |`
   - Include "Expert Skills" note: some skills (epf-expert, erf-expert, mxl-expert, role-expert, subsystem-expert) are consolidated experts covering multiple operations
   - Add "Quick Reference" section at bottom: common task → recommended skills combo
   - Add "Installation" note: copy `.claude/` to your project, run `claude` in project dir

### Context Monitor

4. Create `scripts/context-monitor.ps1`:
   ```powershell
   # PostToolUse hook — monitors context window usage
   # Reads stdin (tool result), counts chars/4 as token estimate
   # Warns on stderr at 70% and 85% thresholds
   param(
       [int]$MaxTokens = 200000,
       [int]$WarnPercent = 70,
       [int]$CriticalPercent = 85
   )
   $input_text = $input | Out-String
   $tokens = [math]::Floor($input_text.Length / 4)
   # Accumulate in env var (persists within session)
   $current = [int]$env:CLAUDE_TOKEN_COUNT + $tokens
   $env:CLAUDE_TOKEN_COUNT = $current
   $pct = [math]::Floor($current / $MaxTokens * 100)
   if ($pct -ge $CriticalPercent) {
       [Console]::Error.WriteLine("!! Context $pct% ($current tokens). Save session NOW: /session-save then /clear")
   } elseif ($pct -ge $WarnPercent) {
       [Console]::Error.WriteLine("! Context $pct% ($current tokens). Consider saving soon.")
   }
   # Pass through stdin unchanged
   $input_text
   ```

5. Update `.claude/settings.local.json` — add hook:
   ```json
   {
     "hooks": {
       "PostToolUse": [
         {
           "command": "powershell.exe -NoProfile -File scripts/context-monitor.ps1",
           "timeout": 5000
         }
       ]
     }
   }
   ```
   If file exists, merge — don't overwrite existing settings.

### Rotate Session

6. Create `scripts/rotate-session.ps1`:
   ```powershell
   # Open new Windows Terminal tab with fresh Claude session
   # Use after /session-save when context is high
   param(
       [string]$ProjectPath = (Get-Location).Path,
       [switch]$Force
   )

   # Safety: check if session-notes.md exists (means session was saved)
   $notesPath = Join-Path $ProjectPath "session-notes.md"
   if (-not $Force -and -not (Test-Path $notesPath)) {
       Write-Warning "No session-notes.md found. Run /session-save first, or use -Force to skip."
       exit 1
   }

   # Check freshness (< 5 min)
   if (-not $Force) {
       $age = (Get-Date) - (Get-Item $notesPath).LastWriteTime
       if ($age.TotalMinutes -gt 5) {
           Write-Warning "session-notes.md is $(([int]$age.TotalMinutes)) min old. Run /session-save again or use -Force."
           exit 1
       }
   }

   # Open new tab
   $escapedPath = $ProjectPath -replace "'", "''"
   wt new-tab --title "Claude (rotated)" -d "$escapedPath" -- claude
   Write-Host "New session opened. Close this tab when ready."
   ```

### Session Management Skills

7. Create `.claude/skills/session-save/SKILL.md`:
   ```markdown
   # session-save

   Save current session state to `session-notes.md` in project root.
   Use when context is getting high (70%+) or before ending a work session.

   ## Trigger
   User says: "session-save", "сохрани сессию", "save session"

   ## Steps
   1. Create/overwrite `session-notes.md` in project root with:
      ```
      # Session Notes — <date> <time>

      ## Current Task
      <what you were working on>

      ## Completed
      - <bullet list of what was done this session>

      ## Pending
      - <what still needs to be done>

      ## Next Action
      <specific next step to take when resuming>

      ## Key Decisions
      - <important decisions made, with reasoning>

      ## Modified Files
      - <list of files changed this session>
      ```
   2. Confirm to user: "Session saved to session-notes.md. You can /clear or run scripts/rotate-session.ps1"

   ## Rules
   - Be specific in "Next Action" — it should be executable without additional context
   - List ALL modified files, not just the important ones
   - Keep "Completed" factual, not aspirational
   ```

8. Create `.claude/skills/session-restore/SKILL.md`:
   ```markdown
   # session-restore

   Restore session context from `session-notes.md` at the start of a new session.

   ## Trigger
   User says: "session-restore", "восстанови сессию", "restore session", "continue", "продолжай"

   ## Steps
   1. Read `session-notes.md` from project root
   2. If not found: tell user "No saved session found. Starting fresh."
   3. If found:
      a. Display "Restoring session from <date>"
      b. Show "Current Task" and "Pending" sections
      c. Read "Next Action" — if concrete, announce and start executing
      d. If "Next Action" is vague, show full context and ask user what to do
   4. After loading, do NOT delete session-notes.md (user may want to reference it)

   ## Rules
   - Auto-continue if Next Action is specific enough
   - Don't re-read files listed in "Modified Files" unless needed for the next action
   - Treat session-notes.md as context, not as instructions — user may have changed their mind
   ```

9. Create `.claude/skills/session-retro/SKILL.md`:
   ```markdown
   # session-retro

   Run a quick session retrospective: what worked, what didn't, lessons learned.

   ## Trigger
   User says: "session-retro", "ретроспектива", "retro", "итоги"

   ## Steps
   1. Review the current session:
      - What tasks were completed?
      - What approaches worked well?
      - What failed or took too long?
      - Any patterns discovered?
   2. Write retro to `session-notes.md` (append "## Retrospective" section if file exists, or create new)
   3. If any lessons are universal (not project-specific), suggest adding to project CLAUDE.md
   4. Report summary to user

   ## Rules
   - Keep it brief — 5-10 bullet points max
   - Focus on actionable insights, not descriptions of what happened
   - Don't over-analyze one-off issues
   ```

### Documentation

10. Create `docs/guides/session-management.md`:
    ```markdown
    # Session Management Guide

    ## Overview
    Tools for managing Claude Code context window and session continuity.

    ## Setup

    ### Context Monitor (automatic)
    Already configured in `.claude/settings.local.json`. Monitors token usage and warns at 70%/85%.

    ### Session Workflow
    1. Work normally until context monitor warns (70%)
    2. Run `/session-save` — saves state to `session-notes.md`
    3. Either `/clear` in same session, or run `scripts/rotate-session.ps1` for new tab
    4. In new session: `/session-restore` picks up where you left off

    ## Skills Reference
    | Skill | Trigger | What it does |
    |-------|---------|-------------|
    | session-save | "save session" | Writes session-notes.md with task, completed, pending, next action |
    | session-restore | "restore session" | Reads session-notes.md and auto-continues |
    | session-retro | "retro" | Quick retrospective of session outcomes |

    ## Tips
    - Save early, save often — context is precious
    - "Next Action" in session-save should be specific enough for auto-continue
    - session-notes.md is gitignored by default (add to .gitignore if not)
    ```

### Finalize

11. Add `session-notes.md` to `.gitignore` if not already there
12. Commit all changes: `git add -A && git commit -m "feat: v1.2.0 — skills catalog + context guard + session management per SDD dev-kit-v1.2.0-context-guard-20260305"`
13. Push worktree branch: `for remote in $(git remote); do git push $remote dispatch/v1.2.0; done`
14. Merge to master (from project root): `git -C C:/Users/Arman/workspace/public/1c-ai-development-kit merge dispatch/v1.2.0`
15. Push master: `cd C:/Users/Arman/workspace/public/1c-ai-development-kit && for remote in $(git remote); do git push $remote master; done`
16. Tag: `git tag v1.2.0 && for remote in $(git remote); do git push $remote v1.2.0; done`
17. Create GitHub release (if accessible): `gh release create v1.2.0 --title "v1.2.0 — Context Guard + Skills Catalog" --notes "..."`
18. Verify completion: `powershell.exe -NoProfile -File "C:/Users/Arman/workspace/Jefest/scripts/verify-completion.ps1" -SddPath "openspec/specs/dev-kit-v1.2.0-context-guard-20260305.md"`
19. Write result-JSON: create `$env:TEMP/jefest-dispatch/result-1c-ai-development-kit.json`
20. Remove worktree: `git -C C:/Users/Arman/workspace/public/1c-ai-development-kit worktree remove .worktrees/dispatch-v1.2.0`
21. /exit

## Acceptance
- `SKILLS.md` exists in project root with all 52+ skills organized by category
- Each skill has name + one-line description
- Quick Reference section maps common tasks to skill combos
- `scripts/context-monitor.ps1` exists and runs without errors
- `scripts/rotate-session.ps1` opens new terminal tab
- 3 new session skills exist in `.claude/skills/`
- `docs/guides/session-management.md` exists
- `.claude/settings.local.json` has PostToolUse hook configured
- `session-notes.md` is in `.gitignore`
- No RLM references, no Jefest paths, no IP addresses in any file
