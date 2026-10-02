# UNIQUE BASKET — Development Workflow

## 1. Branches
| Branch | Purpose | Rules |
|---|---|---|
| `main` | Production-ready code | **Protected.** No direct pushes. Updated only by reviewed PR from `develop` (or hotfix). |
| `develop` | Integration branch | No direct pushes. Updated by reviewed PRs from feature branches. |
| `feature/<scope>-<short-name>` | One feature/fix | Branch from latest `develop`. e.g. `feature/customer-app-checkout`. |
| `hotfix/<name>` | Urgent prod fix | Branch from `main`; merge back into `main` and `develop`. |

- Keep feature branches short-lived; merge `develop` into them to resolve conflicts (no force-push on shared branches).
- One concern per branch/PR. Don't mix backend schema, app UI, and admin changes unless the feature requires it.

## 2. Implementation workflow
1. **Check decisions.** Read `docs/DECISIONS.md`. If the task touches a Pending item (DECISION REQUIRED), stop and ask the project owner.
2. **Check current state.** Read `docs/CURRENT_STATE.md` and the relevant code. Treat old docs and the PDF as reference only.
3. **Plan.** For non-trivial work, write a short plan (scope, files, API/DB impact, tests) and get approval.
4. **Branch** from `develop`.
5. **Implement** in small commits following app-specific `CLAUDE.md` conventions.
6. **Test** (section 3). Add/update tests for every behavior change.
7. **Update docs:** `docs/CURRENT_STATE.md` for implementation changes; `docs/DECISIONS.md` only when the owner confirms a decision.
8. **Open PR** into `develop` with summary, test evidence, and any decisions relied on (by ID).
9. **Review & merge** (section 4).

## 3. Test requirements (must pass before PR)
**Backend** (`backend/`)
- `npm run build` (tsc, no errors)
- `npm test` against a dedicated test PostgreSQL database (never a shared/prod DB), after `NODE_ENV=test npx prisma migrate deploy` and `NODE_ENV=test npx prisma db seed`. Test secrets come from `backend/tests/setup/env.ts`; see `backend/README.md` → Testing.
- Schema change: migration created with `prisma migrate dev`, reviewed, and approved

**Customer app** (`apps/customer_app/`)
- `flutter analyze` → 0 issues
- `flutter test` → all pass
- UI changes: verify responsive viewports per `apps/customer_app/CLAUDE.md`

**Admin** (`apps/admin/`)
- `npm test` (Vitest), `npm run lint` and `npm run build`

Never delete, skip, or weaken tests to get green.

CI: none configured yet (DECISION REQUIRED — P-021).

## 4. Review requirements
- Every PR into `develop` or `main` needs at least one approving review from the project owner (or delegate).
- Reviewer checks: scope matches task; no undecided architecture changed without approval; tests added and passing; no secrets; auth/role/store-isolation preserved; Prisma changes approved; docs updated.
- `develop` → `main`: release PR, full test suite green, owner approval.

## 5. Commit messages
Conventional style: `feat(customer-app): ...`, `fix(backend): ...`, `docs: ...`, `test(...)`, `chore: ...`.

## 6. Environments & secrets
- Use `.env` locally (git-ignored). Provide `.env.example` with variable names only.
- Never commit keys, keystores, `key.properties`, or service-account JSON.
