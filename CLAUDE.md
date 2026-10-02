# UNIQUE BASKET — Claude Code Guide

## Project purpose
UNIQUE BASKET is a multi-store fruit & vegetable ordering platform: a Flutter customer app, a React admin panel, and a Node.js REST API backend.

## Repository structure
```
apps/customer_app/   Flutter customer app (Riverpod, GoRouter, Dio)      → see apps/customer_app/CLAUDE.md
apps/admin/          React + TypeScript + Vite + Tailwind admin panel
backend/             Node.js + TypeScript + Express 5 + Prisma 7 + PostgreSQL → see backend/CLAUDE.md
design/              Screen design specs (reference)
docs/                Project docs (see below)
reference/           UNIQUE BASKET.pdf — client requirements & costing (reference only)
```

Key docs:
- `docs/CURRENT_STATE.md` — what the code currently does (audit findings)
- `docs/DECISIONS.md` — confirmed project decisions + pending decisions
- `docs/DEVELOPMENT.md` — branching, testing, review workflow
- Older docs (`docs/implementation_plan.md`, `docs/MOBILE_*.md`, `apps/customer_app/*.md`, `backend/README.md`) are **reference material**, not decisions. Some are out of date.

## Global architecture (current implementation)
- Clients (customer app, admin panel) talk to the backend over REST at `/api/v1/*`.
- Backend: Express controllers → Prisma → PostgreSQL. JWT access (15m) + refresh (7d) tokens.
- Roles: `customer`, `SUPER_ADMIN`, `STORE_MANAGER` (store-isolated).
- External integrations in code are mocked or env-gated (OTP mock, Razorpay, Firebase Admin). Presence in code ≠ chosen provider.

## Three kinds of information — never mix them
- **CURRENT IMPLEMENTATION** — what the code does today. Source: the code.
- **PROJECT DECISION** — explicitly confirmed by the project owner. Source: `docs/DECISIONS.md` only.
- **UNDECIDED / PENDING** — everything else. Mark as **DECISION REQUIRED**.

Rules:
- Never treat existing code, old docs, or `reference/UNIQUE BASKET.pdf` as a product decision.
- Never invent a decision. If unclear, write "DECISION REQUIRED" and ask.
- **Ask the owner before** changing anything in an undecided area (see Pending Decisions in `docs/DECISIONS.md`), including: payment provider, OTP provider/length, pickup scope, location/maps, notifications.

## Critical business rules already decided
- None of the product/business rules are confirmed yet. See `docs/DECISIONS.md`.
- Payment provider: **DECISION REQUIRED** (backend has Razorpay code; PDF mentions Cashfree; app has no payment SDK). Do not change payment code without approval.

## Git rules
- Work on feature branches (`feature/<name>`); integrate into `develop`; `main` is protected. Details: `docs/DEVELOPMENT.md`.
- Never push to `main` or `develop` directly. Never force-push shared branches.
- Do not commit unless asked. Small, focused commits with clear messages.
- Never commit secrets (`.env`, keys, keystores, service-account JSON).

## Coding rules
- Read existing code and contracts before changing them; follow surrounding conventions.
- Keep changes scoped to the task and to one app/package where possible.
- Backend is the source of truth for prices, totals, stock, fees, and order state; clients must not compute authoritative values.
- Do not modify Prisma schema or migrations without explicit approval.
- Do not add new third-party providers/SDKs without explicit approval.

## Security rules
- No hard-coded secrets; read from env. Do not rely on fallback secrets (`fallback_access_secret`, mock keys) outside local dev.
- Never log tokens, OTPs (outside dev mock), or payment signatures.
- Enforce auth + role + store isolation server-side on every protected route.
- Verify payment/webhook signatures server-side; never trust client payment status.

## Testing rules
- Never delete, skip, or weaken tests to make a change pass.
- Backend: `cd backend && npm test` (Jest + Supertest; needs a test PostgreSQL DB).
- Customer app: `cd apps/customer_app && flutter analyze` (0 issues) and `flutter test`.
- Admin: `cd apps/admin && npm run build` (and lint).
- Add/adjust tests for every behavior change.
