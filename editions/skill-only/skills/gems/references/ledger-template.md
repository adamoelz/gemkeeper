# Ledger: <short mission name>
<!-- gemkeeper ledger. Written for the next session. Keep it under ~120 lines. Edit in place. -->
Updated: <YYYY-MM-DD HH:MM>

## Mission
- <What we are building or fixing, in the user's terms. One or two bullets.>
- Done when: <concrete acceptance criteria>

## Rules
<!-- Hard constraints and preferences. (user) = stated explicitly by the user. -->
- (user) <e.g. Don't change the public API of src/api/client.ts>

## Decisions
<!-- <decision> — because <reason> -->
- <e.g. Use SQLite, not Postgres — because the app must run offline on a single machine>

## Dead ends
<!-- <tried> → <why it failed>. Don't retry these without new information. -->
- <e.g. Upgrading vitest to 3.x → breaks the msw mocks (TypeError: fetch is not a function)>

## Facts
<!-- Non-obvious things a fresh session would trip over. -->
- <e.g. Tests need `pnpm test -- --pool=forks`, threads mode hangs on CI>

## Open questions
- <Things that still need a decision from the user>

## Now
<!-- Rewritten on every sweep, never accumulated. -->
- Done: <...>
- In progress: <file paths + what's half-done>
- Next step: <one concrete action>
