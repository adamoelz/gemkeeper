# Ledger: Stripe webhooks → order fulfillment
<!-- gemkeeper ledger. Written for the next session. Keep it under ~120 lines. Edit in place. -->
Updated: 2026-11-14 16:42

## Mission
- Orders marked `paid` only via Stripe webhooks, never from the client redirect (user)
- Done when: `checkout.session.completed` creates a fulfillment job exactly once, even if Stripe retries; e2e test green

## Rules
- (user) Don't touch `src/legacy/paypal/`. It's being removed next sprint
- (user) No new dependencies without asking
- Money is always integer cents (`amount_cents`), never floats

## Decisions
- Idempotency via unique index on `stripe_events.event_id` — because Stripe retries for up to 3 days and a DB constraint beats an in-memory check across replicas
- Verify signature on the raw body in `src/api/webhooks/stripe.ts` — because the JSON parser middleware mutates the body and breaks `constructEvent`

## Dead ends
- `express.json()` before the webhook route → "No signatures found matching the expected signature". Route must use `express.raw({type: 'application/json'})`
- Fulfilling inside the webhook handler → handler times out (>10s) under load and Stripe retries. Enqueue a job instead
- `stripe listen --forward-to localhost:3000` from WSL → events never arrive; run it in Windows PowerShell

## Facts
- Local webhook secret changes on every `stripe listen` run: copy it into `.env` as `STRIPE_WEBHOOK_SECRET`
- e2e: `pnpm test:e2e -- webhooks` needs `docker compose up redis` first

## Open questions
- Refunds: auto-cancel the fulfillment job or flag it for manual review? (ask the user)

## Now
- Done: raw-body route, signature check, `stripe_events` table + unique index (migration 0042)
- In progress: `src/jobs/fulfillOrder.ts`, retry with backoff is written but untested
- Next step: write `tests/e2e/webhooks.spec.ts` case "duplicate event delivered twice → one job"
