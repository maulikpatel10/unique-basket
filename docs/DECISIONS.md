# UNIQUE BASKET — Project Decisions

This file records **only decisions explicitly confirmed by the project owner**.

- Existing code is **not** a decision.
- Older docs (`docs/implementation_plan.md`, `docs/MOBILE_*.md`, app/backend READMEs) are **not** decisions.
- `reference/UNIQUE BASKET.pdf` is **requirements/reference material**, not a decision.

Each entry should include: date, decision, confirmed by, notes.

---

## Confirmed Decisions

### D-001 — Documentation separates implementation, decisions, and pending items
- **Date:** 2026-10-02
- **Confirmed by:** Project owner (instruction in Claude Code session)
- **Decision:** Project docs must distinguish CURRENT IMPLEMENTATION, PROJECT DECISION, and UNDECIDED/PENDING. Unclear items are marked "DECISION REQUIRED". Decisions must not be inferred from code or the reference PDF.

### D-002 — Payment provider is undecided
- **Date:** 2026-10-02
- **Confirmed by:** Project owner
- **Decision:** No payment provider is chosen. Neither Razorpay nor Cashfree is selected. Payment code must not be modified until a provider is decided. (Listed under Pending as P-001.)

### D-003 — Git branching model
- **Date:** 2026-10-02
- **Confirmed by:** Project owner (requested in documentation brief)
- **Decision:** Feature branches → integrate into `develop` → `main` is protected. Details in `docs/DEVELOPMENT.md`.

> No product or business rules (pricing, fees, COD, OTP, pickup, delivery radius, etc.) have been confirmed yet.

---

## Pending Decisions

All items below are **DECISION REQUIRED**. Do not implement or change these areas without owner confirmation.

| ID | Topic | Current implementation (code) | Reference material | Status |
|----|-------|-------------------------------|--------------------|--------|
| P-001 | Payment provider | Backend: Razorpay SDK, order creation, signature verify, webhook; Prisma `Payment` has `razorpay_*` columns. App: no payment SDK; "UPI" option sends `ONLINE` and goes straight to success screen. | PDF: Cashfree (feature list); costing lists both Cashfree and Razorpay | DECISION REQUIRED |
| P-002 | Online payment UX/flow in app | Not implemented | — | DECISION REQUIRED |
| P-003 | OTP / SMS provider | In-memory mock, logs OTP to console; no SMS gateway | PDF: MSG91 | DECISION REQUIRED |
| P-004 | OTP length | App: 4 digits. Backend: `1234` in dev/test, 6 digits otherwise. Old docs: 6 digits | — | DECISION REQUIRED |
| P-005 | OTP storage / rate limits / expiry | In-memory Map (lost on restart, single instance); 5 min expiry, 3 attempts, 5 req/hr | Old plan: hashed in cache/DB | DECISION REQUIRED |
| P-006 | Pickup scope (customer app) | Backend supports PICKUP orders + manager pickup verification; app checkout hard-codes `DELIVERY` | Old plan describes pickup; PDF does not mention pickup | DECISION REQUIRED |
| P-007 | Location provider (GPS / geocoding) | No location/geocoding package; addresses carry lat/lng supplied by client | Old plan: geocoding/Google Maps | DECISION REQUIRED |
| P-008 | Maps provider | None | PDF: external navigation via Google/Apple Maps, no SDK initially | DECISION REQUIRED |
| P-009 | Notification provider | Backend: firebase-admin, falls back to console mock; in-app notifications in DB. App: no FCM package | PDF: Firebase FCM | DECISION REQUIRED |
| P-010 | Serviceability model | Both pincode whitelist (`SupportedPincode`, defaults Rajkot/Gujarat) and store radius (Haversine) exist | PDF: "delivery zones" in settings | DECISION REQUIRED |
| P-011 | Delivery fee / free threshold / minimum order / COD rules & values | Admin-configurable `DeliverySettings` (defaults ₹30 / ₹499 / ₹199 / COD ₹20, ₹100–₹5000) | — | DECISION REQUIRED |
| P-012 | Order status lifecycle | 8 statuses incl. `PICKED_UP`; transition table in admin controller | — | DECISION REQUIRED |
| P-013 | Refunds / cancellations by customer | `REFUNDED` status removed; no customer cancel endpoint | — | DECISION REQUIRED |
| P-014 | Subcategories, filters, sorting | Flat categories only | PDF: subcategories, filters/sorting | DECISION REQUIRED |
| P-015 | Delivery personnel / delivery management | Not implemented (no delivery role/app) | PDF: admin assigns delivery personnel; README mentions delivery apps | DECISION REQUIRED |
| P-016 | Image storage | URLs only; no upload storage | PDF: Supabase storage | DECISION REQUIRED |
| P-017 | Backend hosting / deployment | Not configured | PDF: Render or Railway | DECISION REQUIRED |
| P-018 | Admin features: reports, broadcast notifications | Not implemented | PDF lists them | DECISION REQUIRED |
| P-019 | Saved payment methods in app | Stored locally in SharedPreferences (UI only) | — | DECISION REQUIRED |
| P-020 | Customer-app scope rule in `apps/customer_app/AGENTS.md` ("never modify backend/admin/root") | Existing doc | — | DECISION REQUIRED (keep or replace with root rules) |
| P-021 | CI pipeline and required checks | No CI config in repo | — | DECISION REQUIRED |
| P-022 | Customer app Clean Architecture `domain/` layer | Docs require it; no `domain/` folders exist | — | DECISION REQUIRED |
