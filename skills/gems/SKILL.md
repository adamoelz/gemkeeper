---
name: gems
description: Keeps a tiny, always-current ledger of the mission-critical facts of a coding session (goal, hard rules, decisions and why, dead ends, current state, next step) in .gemkeeper/ledger.md so the session can be cleared or compacted at any time without losing what matters. Use proactively whenever a decision is made, a constraint or user preference is stated, an approach fails, or a non-obvious fact is discovered; when a [gemkeeper] checkpoint or context warning appears; and when the user says "gems", "save gems", "sweep", "handoff", "save progress", "context is getting long", or is about to /clear or /compact.
---

# Gems: keep the 2% of context that matters

Most of a long session is noise: file dumps, tool output, abandoned drafts. A small part
is gold: what we are building, the rules we must not break, what we decided and why,
what already failed, where we are right now. This skill keeps that gold in one short file,
`.gemkeeper/ledger.md` at the project root, **while the session is still sharp**, so the
user can `/clear` a bloated session at any moment and continue at full quality.

The ledger is written for the next instance of you, not for the human. Be dense, exact, and literal.

## The ledger test

Before writing anything, ask: **"Would a fresh session with only the code and this ledger
get this wrong or waste time on it?"**

- Yes → it is a gem. Write it.
- No (it's in the code, in git history, in CLAUDE.md, or easy to rediscover) → leave it out.

Gems, typically:

- The goal, in the user's own terms, and what "done" means
- Hard constraints and user preferences ("never touch the public API", "no new deps", "user wants German UI strings")
- Decisions **with the reason**. A decision without its reason gets reversed by the next session.
- Dead ends: what was tried, why it failed. This is the most valuable and most often lost category.
- Non-obvious facts: env quirks, the exact command that works, the flaky test, the misleading error message
- Current state and the very next concrete step

Not gems: file contents, long code, step-by-step history, things already committed and self-explanatory, pleasantries.

## Format

Use the template in `references/ledger-template.md`. Rules:

- One fact per bullet, one or two lines. Prefer exact identifiers: paths, function names, commands, error strings.
- Decisions: `<decision> — because <reason>`. Dead ends: `<tried> (by whom, when; still in the code or reverted?) → <why it failed>`.
- **One topic, one bullet.** Before adding, search the ledger for the topic and update that bullet instead of adding a second one.
- **Edit in place, never just append.** Update a bullet when it changes; delete it when it stops being true. When a value changes (test count, port, version), replace the old value; never leave both.
- Leave out what the code, the diff or a file already shows: data values, raw measurements that drove no decision, implementation details.
- Hard cap: about 120 lines. If over, merge and prune. Oldest resolved items go first.
- `## Now` is always rewritten, never accumulated. It holds the current state and **one** next step.
- Mark anything the user said explicitly with `(user)`. Those bullets outrank your own inferences.

## Modes

### 1. Capture (continuous, default)

Whenever something passes the ledger test, update the ledger right away with a single small
edit, then carry on with the task. Don't announce it beyond a short note like `(gem saved)`.
Don't batch gems "for later". Later is when context is bloated and details are already blurred.

Side remarks are the easiest gems to lose: "heads-up", "by the way", "for later", "I tried X last week".
Capture them even when the current task doesn't need them.

When a `[gemkeeper] gem check` appears, the user's message probably holds a gem: save what is missing
**in the same step as your first action** of the turn: one Bash command that inserts the bullet under its
heading (for example `sed -i '/^## Rules/a - ...' .gemkeeper/ledger.md` with GNU sed; adapt to the platform), issued as a parallel tool call
next to that action. No extra step and no Read before it: you know the ledger from the session start and
your own edits. Duplicates are merged in the next sweep. When a `[gemkeeper] checkpoint` reminder
appears, glance back over the turns since the last checkpoint, save anything that passes the test,
and continue. If nothing qualifies, do nothing.

A new session continues the same ledger. The injected ledger is not read-only: keep capturing.

### 2. Sweep (user says "gems", "sweep", "handoff", "save progress", or a context warning appears)

A full pass before a reset:

1. Read the current `.gemkeeper/ledger.md` (create it from the template if missing).
2. Go through **every user message** in the conversation, one by one, and check each against the ledger: rules ("never", "always", "don't"), reasons ("because"), dead ends ("tried", "didn't work"), side remarks and gotchas (flaky tests, ports, commands, "heads-up"). Then do the same for your own discoveries: approaches that failed, non-obvious facts.
3. Verify claims about state against reality where cheap: `git status`, `git log -5 --oneline`, whether the files you mention exist.
4. Rewrite `## Now`: what is done, what is half-done (with file paths), and the single next step.
5. Prune: remove stale or duplicated bullets and stay under the cap.
6. Reply with at most three lines: the mission, the next step, and `Safe to /clear: the ledger will be loaded automatically.` (If the hooks aren't installed, say `Start the next session with: read .gemkeeper/ledger.md`.)

### 3. Resume (the ledger was injected at session start, or the user says "resume" or "continue")

1. Treat the ledger as the source of truth for intent; treat the code as the source of truth for state.
2. Check `## Now` against `git status` and `git log`. If they disagree, trust the repo and fix the ledger.
3. Reply in at most three lines: the mission, where we are, and the next step you are about to take. Then wait for the user's go-ahead, unless they already gave you a task.

### 4. Close (the mission is done or the user switches topics)

Move the ledger to `.gemkeeper/archive/<YYYY-MM-DD>-<short-slug>.md` and start a fresh one.
Carry over only the bullets under `## Rules` and `## Facts` that still apply to the new work.

## Guardrails

- Never put secrets, tokens, or credentials in the ledger. Name where they live instead (`API key in .env as FOO_KEY`).
- Never invent gems. If you are unsure whether the user decided something, write it as `open question:` instead.
- The ledger never replaces doing the work. Capture takes seconds; don't let it derail the task.
- If `.gemkeeper/` is not in `.gitignore` and the user hasn't decided, ask once whether the ledger should be committed (good for teams) or ignored (good for private notes).
