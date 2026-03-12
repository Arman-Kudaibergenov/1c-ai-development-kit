# SDD: dev-kit cleanup — Cursor→Claude Code + README update

## Context
Project migrated from Cursor to Claude Code but old files still reference "Cursor IDE" and `.cursor/`. Also README needs update about v1.2.0 features (Context Guard, session management, SKILLS.md).

## Environment
- Project: 1c-ai-development-kit, path: C:\Users\Arman\workspace\public\1c-ai-development-kit
- Skills: code-review, workflow-automation

## Compatibility
- OS: win32
- Required tools: Bash, Read, Write, Edit
- Profile: budget

## Approach
1. Fix all Cursor references in old docs
2. Update README with v1.2.0 features (context guard, session management, skills catalog)

## Files
- `COMMUNITY_ANNOUNCEMENT.md` — EDIT — Cursor→Claude Code, .cursor→.claude
- `CONTRIBUTING.md` — EDIT — Cursor→Claude Code, .cursor→.claude
- `PROJECT_SUMMARY.md` — EDIT — Cursor→Claude Code, .cursor→.claude
- `README.md` — EDIT — add v1.2.0 section: Context Guard (context-monitor.ps1 hook), session management (session-save/restore/retro skills), rotate-session.ps1, SKILLS.md catalog link

## Atomic Tasks

1. Create worktree: `git worktree add .worktrees/dispatch-cleanup -b dispatch/cleanup`
2. cd `.worktrees/dispatch-cleanup`

3. In `COMMUNITY_ANNOUNCEMENT.md`:
   - Replace "Cursor IDE" → "Claude Code"
   - Replace `.cursor/` → `.claude/`
   - Replace "Перезапустите Cursor" → "Перезапустите Claude Code"
   - Update any install instructions to reflect .claude/ structure

4. In `CONTRIBUTING.md`:
   - Replace "Cursor" → "Claude Code" everywhere
   - Replace `.cursor/` → `.claude/`
   - Update directory structure example

5. In `PROJECT_SUMMARY.md`:
   - Replace "Cursor IDE" → "Claude Code"
   - Replace `.cursor/` → `.claude/`

6. Grep entire project for remaining "cursor" references (case-insensitive) in .md files. Fix any found. Exception: `.cursor/` directory reference in .gitignore is OK to keep for backwards compat.

7. In `README.md` — add/update section about v1.2.0 features:
   ```
   ## Context Guard & Session Management (v1.2.0)

   Инструменты для управления контекстным окном Claude Code:

   ### Context Monitor
   Автоматический hook (PostToolUse) — отслеживает использование контекста и предупреждает на 70% и 85%.
   Настроен в `.claude/settings.local.json`.

   ### Session Management
   Три скилла для сохранения и восстановления сессий:
   - `/session-save` — сохраняет состояние в `session-notes.md` (задача, прогресс, следующий шаг)
   - `/session-restore` — восстанавливает контекст из `session-notes.md` при старте новой сессии
   - `/session-retro` — ретроспектива сессии (что сработало, что нет)

   ### Rotate Session
   `scripts/rotate-session.ps1` — открывает новый таб Windows Terminal с чистой сессией Claude Code.

   ### Skills Catalog
   Полный каталог всех 63 скилов (52 проектных + 11 глобальных) по 13 категориям: [SKILLS.md](SKILLS.md)
   ```

## Acceptance
- No "Cursor" references remain in .md files (except .gitignore backwards compat)
- README has v1.2.0 Context Guard section
- All .cursor/ paths replaced with .claude/

## Finalize
1. Commit: `git add -A && git commit -m "docs: Cursor→Claude Code migration + v1.2.0 Context Guard docs per SDD dev-kit-cleanup-cursor-refs-20260305"`
2. Push worktree: `for remote in $(git remote); do git push $remote dispatch/cleanup; done`
3. Merge to master: `git -C C:/Users/Arman/workspace/public/1c-ai-development-kit merge dispatch/cleanup`
4. Push master: `cd C:/Users/Arman/workspace/public/1c-ai-development-kit && for remote in $(git remote); do git push $remote master; done`
5. Remove worktree: `git -C C:/Users/Arman/workspace/public/1c-ai-development-kit worktree remove .worktrees/dispatch-cleanup`
6. Write result-JSON
7. /exit
