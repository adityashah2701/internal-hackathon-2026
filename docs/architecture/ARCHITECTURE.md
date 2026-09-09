# PS-089 System Architecture

## 1. Monorepo Structure

The project is structured as a monorepo managed with Melos:

```text
internal-hackathon-2026/
├── apps/
│   └── mobile/           # Flutter Mobile Application
├── packages/             # Shared Dart packages (future domain models / UI components)
├── supabase/             # Supabase configuration, migrations, edge functions, seed
├── docs/                 # Product & technical documentation
├── melos.yaml            # Monorepo task orchestration
└── AGENT_RULES.md        # Architectural constraints and guidelines
```

## 2. Flutter Mobile Application Architecture

The mobile app follows a **Feature-First Layered Architecture**:

```text
lib/
├── core/                 # Shared across features
│   ├── config/           # App configuration (URL, keys, environment modes)
│   ├── constants/        # System constants & design tokens
│   ├── errors/           # Custom AppException and Failure definitions
│   ├── network/          # Network clients (Supabase client provider)
│   ├── routing/          # GoRouter configuration & role-based guards
│   ├── theme/            # Theme, color palettes, typography tokens
│   └── utils/            # Logging, helpers
├── data/                 # Common data layer
│   ├── datasources/      # Remote and local data source interfaces
│   ├── models/           # Typed serialization models
│   └── repositories/     # Repository implementations
├── features/             # Domain feature modules
│   ├── auth/             # Login, registration, role selection
│   ├── customer/         # Booking, discovery, reviews, payment
│   ├── worker/           # Radar, job acceptance, OTP verification, ledger
│   ├── cooperative/      # KYC review, roster, welfare fund management
│   ├── federation/       # Cross-cooperative analytics, AI demand forecasting
│   └── verification/     # Developer verification screen
└── l10n/                 # Localization ARB files (en, hi, mr)
```

## 3. Supabase Integration

* **Supabase Client**: Single central initialization via `Supabase.initialize()` in `lib/core/network/supabase_client.dart`.
* **State Management**: `flutter_riverpod` exposes providers for Supabase client, auth state, and feature states.
* **Realtime**: PostgreSQL CDC feeds for real-time booking dispatches, live OTP handshake, and status changes.
* **Storage**: Buckets for KYC documents, trade skill certificates, and user avatars.

## 4. Configuration & Security Strategy

* **Zero Hardcoded Secrets**: Secrets are never checked into git.
* **Compile-Time Definitions**: In Flutter, configurations are injected via `--dart-define-from-file=.env` or `--dart-define` flags into `AppConfig`.
* **Client Boundaries**: Only the Supabase Project URL and public Anonymous (`anon`) key are accessible in the mobile client. Service-role keys, database passwords, and private tokens are strictly forbidden in client code.

## 5. Authentication & Future Role Model

* **Identity Provider**: Supabase Auth (Phone OTP & Password / Magic link).
* **Role Hierarchy**:
  1. `Customer`: Service discovery, booking, invoicing, ratings.
  2. `Worker`: Job alerts, OTP completion, welfare & earnings ledger.
  3. `Cooperative Admin`: Member onboarding, KYC verification, society welfare fund.
  4. `Federation Admin`: Apex overview, inter-society resource balancing, AI demand allocation.
* **Centralized RBAC**: User role is linked to an application `profiles` table. Navigation uses `GoRouter` redirect guards, while database access is strictly governed by PostgreSQL Row Level Security (RLS).

## 6. Data Access Strategy

* **Repository Pattern**: Features interact with domain repositories rather than raw database calls.
* **Typed Domain Entities**: All responses are parsed into immutable Dart data classes.
* **Explicit Error Handling**: Exceptions are caught at datasource/repository boundaries and converted into user-friendly `Failure` objects for Riverpod state consumers.

## 7. Scalability & Extensibility

* **Monorepo Readiness**: Future web dashboards (e.g. Next.js cooperative portal) or shared Dart SDKs can be added under `apps/` or `packages/` without altering core architecture.
* **Localization Ready**: Flutter `intl` & ARB setup handles English, Hindi, and Marathi dynamically without layout breakages.
