# PS-089 — Cooperative-Owned Digital Service Marketplace

A production-grade digital service marketplace tailored for Labour Cooperative Federations and Labour Cooperative Societies. Built for Smart India Hackathon.

---

## Repository Structure

```text
internal-hackathon-2026/
├── apps/
│   └── mobile/           # Primary Flutter mobile client (Customer, Worker, Society, Federation)
├── packages/             # Shared Dart packages (created when shared responsibilities emerge)
├── supabase/             # Supabase backend (PostgreSQL schemas, RLS policies, Edge Functions, seed data)
│   ├── migrations/
│   ├── functions/
│   └── seed/
├── docs/                 # System architecture and product specifications
│   ├── architecture/
│   └── product/
├── melos.yaml            # Melos monorepo configuration
├── AGENT_RULES.md        # Architectural guidelines and engineering rules
└── PRODUCT_SPECIFICATION.md # Full product requirements document
```

---

## Tech Stack

* **Mobile**: Flutter 3.44+ (Dart 3.12+), Riverpod, GoRouter, Material 3
* **Backend**: Supabase (PostgreSQL 15+, Supabase Auth, Storage, Realtime, Edge Functions)
* **Monorepo Tooling**: Melos
* **Localization**: Built-in Flutter `l10n` (English, Hindi, Marathi)

---

## Getting Started

### Prerequisites
* Flutter SDK (3.44+) & Dart SDK (3.12+)
* Node.js (v20+) & npm (for Supabase CLI)
* Docker (for local Supabase development)

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repo-url>
   cd internal-hackathon-2026
   ```

2. **Mobile App Setup:**
   ```bash
   cd apps/mobile
   cp .env.example .env
   flutter pub get
   flutter run
   ```

3. **Backend Setup (Local Supabase):**
   ```bash
   npx supabase start
   ```

---

## Implemented Foundations
* **Phase 1: Project Initialization**: Monorepo structure (Melos), Flutter 3.44+ base app, Riverpod state management, GoRouter routing, localization (`en`, `hi`, `mr`), unified theme.
* **Phase 2: Auth, RBAC & Onboarding**:
  * Supabase Auth integration (email/password sign-in & sign-up, persistent sessions, reactive state).
  * Typed `UserRole` (`customer`, `worker`, `cooperative_admin`, `federation_admin`).
  * Onboarding gateway with public role self-selection guarded against admin escalation.
  * PostgreSQL schema & RLS policies with trigger-enforced privilege integrity (`supabase/migrations/`).
  * Role-routed home screen destinations.

---

## Development & Testing Commands
* **Run static analysis**: `cd apps/mobile && flutter analyze`
* **Run test suite**: `cd apps/mobile && flutter test`
* **Run mobile app**: `cd apps/mobile && flutter run`

---

## Engineering Rules
All engineering work adheres strictly to [AGENT_RULES.md](AGENT_RULES.md).
Key tenets:
* **Architecture First**: Understand requirements, entities, auth, and state before writing code.
* **Strict Type Safety**: No dynamic escapes or unvalidated casts.
* **Security at Database Layer**: RLS policies enforce RBAC, not client UI.

