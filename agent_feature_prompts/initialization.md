# PS-089 — APPLICATION INITIALIZATION

You are the lead engineer initializing a new, scalable monorepo for our Smart India Hackathon project **PS-089**.

Your responsibility at this stage is ONLY to initialize the application foundation correctly.

Do not implement business features yet.

---

# 1. PRODUCT CONTEXT

PS-089 is a cooperative-owned digital service marketplace for Labour Cooperative Federations and Labour Cooperative Societies.

The platform connects:

* Customers who need services
* Verified workers/service providers
* Labour Cooperative Societies
* Labour Cooperative Federations

Core future capabilities include:

* Worker registration and verification
* Skill and certification management
* Customer service booking
* Geo-location based worker matching
* Digital payments and invoicing
* Ratings and feedback
* Worker welfare and insurance
* Emergency/on-demand services
* Cooperative/federation administration
* Multilingual support
* AI-based demand forecasting and workforce allocation

The primary application is a **Flutter mobile application**.

---

# 2. CURRENT TECHNOLOGY DECISIONS

Use:

### Mobile

* Flutter
* Dart

### Backend

* Supabase

### Database

* PostgreSQL through Supabase

### Backend capabilities

* Supabase Auth
* Supabase Storage
* Supabase Realtime
* Supabase Edge Functions when required

### Future applications

The repository must be capable of supporting:

* Flutter mobile application
* Future Next.js web administration portal
* Future additional applications if required

Do NOT implement the future web application now.

---

# 3. MONOREPO REQUIREMENT

Initialize the repository as a clean monorepo.

Recommended high-level structure:

```text
ps089/
│
├── apps/
│   └── mobile/
│
├── packages/
│
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed/
│
├── docs/
│   ├── architecture/
│   └── product/
│
├── .gitignore
├── README.md
└── melos.yaml
```

However:

**Do NOT create unnecessary packages merely to make the repository look sophisticated.**

Initially:

```text
apps/mobile
supabase
docs
```

are sufficient.

Only create a package under `packages/` if there is a real shared responsibility that requires it.

The architecture must make it easy to introduce shared packages later.

---

# 4. FIRST ACTION — INSPECT THE ENVIRONMENT

Before creating or modifying anything:

Inspect:

* Operating system
* Flutter installation
* Dart installation
* Flutter version
* Dart version
* Git
* Node/npm availability if relevant to tooling
* Supabase CLI availability
* Existing project files
* Existing repository state

If an existing project is present, do NOT destroy or overwrite it blindly.

Determine whether this is:

* A fresh project
* A partially initialized project
* An existing application that needs restructuring

---

# 5. READ CURRENT OFFICIAL DOCUMENTATION

Before performing setup, read the CURRENT official documentation for:

* Flutter project creation
* Dart package management
* Flutter monorepo/workspace recommendations
* Melos
* Supabase Flutter
* Supabase CLI
* Supabase local development
* Supabase migrations
* Supabase configuration
* Supabase Auth

Use documentation compatible with the actual installed versions.

Do not rely on old tutorials.

Do not copy deprecated commands.

Do not invent configuration.

If a tool/API has changed, use the current recommended approach.

---

# 6. MONOREPO TOOLING

Evaluate whether **Melos** is appropriate for the repository.

If using Melos:

* Configure it correctly for the repository.
* Keep the configuration minimal.
* Do not create unnecessary packages.
* Ensure future Flutter packages can be added easily.

Do not introduce additional monorepo tooling unless there is a clear reason.

---

# 7. CREATE THE FLUTTER APPLICATION

Create:

```text
apps/mobile/
```

as the primary Flutter application.

Use:

* Dart null safety
* Current stable Flutter conventions
* Appropriate project metadata
* Clean application entry point

The application must run successfully before continuing.

---

# 8. FLUTTER ARCHITECTURE

Inside the mobile application, establish a clean feature-oriented architecture.

Prefer:

```text
apps/mobile/
└── lib/
    ├── core/
    │   ├── config/
    │   ├── constants/
    │   ├── errors/
    │   ├── routing/
    │   ├── theme/
    │   └── utils/
    │
    ├── data/
    │   ├── models/
    │   ├── repositories/
    │   └── datasources/
    │
    ├── features/
    │
    └── main.dart
```

Do not create empty files simply to fill directories.

The architecture should support future feature modules such as:

```text
features/
├── auth/
├── worker/
├── customer/
├── cooperative/
├── federation/
├── booking/
├── payments/
├── reviews/
├── notifications/
├── location/
├── welfare/
└── forecasting/
```

But **do not implement these features yet**.

---

# 9. SUPABASE SETUP

Configure Supabase as the backend platform.

Prepare the project for:

```text
Flutter
   ↓
Supabase Flutter SDK
   ↓
Supabase
   ├── Auth
   ├── PostgreSQL
   ├── Storage
   ├── Realtime
   └── Edge Functions
```

The Flutter application must have a properly initialized Supabase client.

Use the current official initialization approach.

There must be one consistent Supabase client configuration rather than random client instances throughout the application.

---

# 10. ENVIRONMENT CONFIGURATION

Do NOT hardcode environment-specific configuration throughout the codebase.

Create a clean configuration mechanism for:

* Supabase URL
* Supabase public/anonymous client key

Important:

NEVER place these inside the Flutter application:

* Supabase service-role key
* Database password
* Private server secrets
* Payment secret keys
* AI provider secret keys

The mobile application is a client application and must only contain credentials safe for client-side use.

---

# 11. SUPABASE PROJECT STRUCTURE

Create the backend directory:

```text
supabase/
├── migrations/
├── functions/
└── seed/
```

Do not create the complete PS-089 database schema yet.

Do not prematurely create tables for:

* workers
* jobs
* bookings
* payments
* reviews
* cooperatives
* federations

Those will be designed after the product/domain model is finalized.

The Supabase structure should simply be ready for future migrations and Edge Functions.

---

# 12. DATABASE PHILOSOPHY

The eventual database will use PostgreSQL.

Before implementing database features:

* Understand domain relationships.
* Define ownership.
* Define foreign keys.
* Define constraints.
* Define indexes.
* Define Row Level Security.
* Define role/permission boundaries.

Do not treat Supabase/PostgreSQL as an untyped JSON storage system.

Do not create duplicate concepts under different names.

---

# 13. AUTHENTICATION FOUNDATION

Prepare the application architecture for Supabase Auth.

Future user flow:

```text
User
 ↓
Supabase Auth
 ↓
Authenticated Session
 ↓
Application Profile
 ↓
Role
```

Future roles:

```text
Customer
Worker
Cooperative Admin
Federation Admin
```

Do NOT implement the full login/signup experience yet.

Do NOT hardcode a user's role.

Do NOT implement full RBAC yet.

Only make sure the architecture can support it cleanly.

---

# 14. STRICT TYPE SAFETY

This project must follow strict Dart type safety.

Rules:

* Avoid `dynamic`.
* Avoid unnecessary `Object?`.
* Avoid giant `Map<String, dynamic>` structures.
* Handle nullable values explicitly.
* Avoid unnecessary `!`.
* Avoid unsafe casts.
* Prefer typed models.
* Prefer enums/sealed types for domain states.
* Never use strings for critical domain states when a typed representation is appropriate.

Example:

Avoid:

```dart
if (status == "completed") {}
```

Prefer a typed domain representation when implementing the actual feature.

---

# 15. ERROR HANDLING FOUNDATION

Establish a simple reusable error strategy.

It must eventually support:

* Network errors
* Supabase errors
* Authentication errors
* Authorization errors
* Validation errors
* Storage errors
* Unexpected exceptions

Do not silently swallow exceptions.

Do not expose raw database/server errors directly to users.

Do not create an enormous error framework at this stage.

Keep it simple and extensible.

---

# 16. STATE MANAGEMENT

Inspect the current project before selecting a state-management solution.

If the project has none, choose an appropriate solution based on:

* Current Flutter ecosystem
* Project complexity
* Team familiarity
* Maintainability
* Compatibility with Supabase

Use ONE primary state-management approach.

Do not introduce multiple competing solutions.

Do not over-engineer state management during initialization.

---

# 17. NAVIGATION FOUNDATION

Prepare a centralized navigation architecture.

It must eventually support:

```text
Unauthenticated
      ↓
Authenticated
      ↓
Role
 ├── Customer
 ├── Worker
 ├── Cooperative Admin
 └── Federation Admin
```

Do not implement all role-specific routes yet.

The navigation architecture should make protected routes and role-based routing possible later.

---

# 18. THEME / UI FOUNDATION

Create a basic centralized theme.

Establish:

* Typography
* Spacing conventions
* Border radius conventions
* Basic color scheme
* Light/dark support if practical

Do NOT design the complete PS-089 UI yet.

Create only a minimal placeholder screen proving the application shell works.

---

# 19. LOCALIZATION FOUNDATION

The PS requires a multilingual mobile application.

Prepare the architecture for localization.

Initial languages:

* English
* Hindi
* Marathi

Do NOT translate the entire application during initialization.

Do NOT hardcode architecture around one language.

Ensure future screens can use localized strings rather than hardcoded user-facing text.

---

# 20. SECURITY FOUNDATION

Security must be considered from the beginning.

The future application will use Supabase Row Level Security.

Architecture must support:

```text
Authentication
      ↓
User identity
      ↓
Role
      ↓
Permission
      ↓
Database authorization
```

Never rely solely on:

```text
if (role == admin)
```

inside Flutter.

Client-side checks are for UX.

Actual authorization must eventually be enforced server-side/database-side.

---

# 21. DEPENDENCY DISCIPLINE

Before adding a dependency:

1. Check whether Flutter already provides the capability.
2. Check existing dependencies.
3. Read the latest official documentation.
4. Verify compatibility with the installed Flutter/Dart version.
5. Check maintenance status.
6. Add it only if necessary.

Do NOT install packages speculatively.

Do NOT add packages simply because they are popular.

---

# 22. MINIMAL VERIFICATION SCREEN

Create a very small development-only verification mechanism that confirms:

```text
Flutter application
        ↓
Supabase client
        ↓
Supabase project
```

Do not display:

* API keys
* Tokens
* Database credentials
* Private information

The goal is simply to verify connectivity/configuration.

---

# 23. NO BUSINESS FEATURES YET

At this stage DO NOT implement:

* Worker registration
* Customer registration
* Login UI
* Worker verification
* Certifications
* Booking
* Scheduling
* Geo matching
* Payments
* Invoices
* Ratings
* Welfare
* Insurance
* Emergency services
* AI forecasting
* Admin dashboards
* Federation dashboards

Only initialize the foundation.

---

# 24. VALIDATION

After initialization, run the appropriate checks.

At minimum:

```bash
flutter analyze
flutter test
```

and verify the application builds/runs successfully.

If Supabase CLI is used, verify its configuration as well.

Fix all errors introduced during setup.

Do not leave known analyzer errors.

---

# 25. FINAL PROJECT STRUCTURE

The final result should be approximately:

```text
ps089/
│
├── apps/
│   └── mobile/
│       ├── android/
│       ├── ios/
│       ├── lib/
│       │   ├── core/
│       │   ├── data/
│       │   ├── features/
│       │   └── main.dart
│       ├── test/
│       └── pubspec.yaml
│
├── packages/
│
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed/
│
├── docs/
│   ├── architecture/
│   └── product/
│
├── melos.yaml
├── README.md
└── .gitignore
```

The exact structure may differ if you identify a better architecture, but explain why before making a significant deviation.

---

# 26. DOCUMENT THE ARCHITECTURE

Create/update:

```text
docs/architecture/
```

with a short architecture document explaining:

* Monorepo structure
* Flutter application structure
* Supabase integration
* Configuration strategy
* Authentication direction
* Future role model
* Data access strategy
* Future scalability strategy

Keep it concise and useful.

Do not write a 50-page architecture document.

---

# 27. GIT / REPOSITORY HYGIENE

Ensure:

* Secrets are ignored
* Build artifacts are ignored
* IDE-specific files are handled appropriately
* Environment files containing secrets are ignored
* README explains setup

Do not commit credentials.

---

# 28. FINAL REPORT

After completing initialization, report:

## Environment

* Flutter version
* Dart version
* Supabase CLI version if installed

## Architecture

Show the final directory structure.

## Dependencies

List every dependency added and why.

## Supabase

Explain:

* Client initialization
* Configuration strategy
* Auth readiness
* Database readiness
* Storage readiness
* Realtime readiness

## Verification

Confirm:

* Flutter app runs
* Supabase connection works
* `flutter analyze` passes
* Tests pass
* No secrets are committed
* No unnecessary dependencies were added

## Important Decisions

List any architectural decisions that deviate from this prompt and explain why.

## Next Step

Do NOT automatically implement the next feature.

Recommend the next logical development step based on the architecture.

---

# ABSOLUTE ENGINEERING RULE

Follow this sequence:

```text
INSPECT
   ↓
UNDERSTAND
   ↓
READ CURRENT OFFICIAL DOCS
   ↓
PLAN
   ↓
INITIALIZE
   ↓
VERIFY
   ↓
DOCUMENT
```

Never:

```text
CREATE FILES RANDOMLY
   ↓
INSTALL PACKAGES
   ↓
COPY OLD TUTORIALS
   ↓
PATCH ERRORS
```

The goal is not to produce the maximum amount of code.

The goal is to create a **clean, type-safe, secure, scalable foundation that the team can confidently build PS-089 on top of.**

Do not implement business functionality until this initialization is complete and verified.
