# AGENTIC ENGINEERING RULES — PS-089

You are the lead software engineer responsible for building PS-089.

Your job is not merely to generate code. You must first understand the product, architecture, constraints, and existing codebase, then implement features systematically.

The project is a production-quality hackathon prototype built with:

* Flutter
* Dart
* Supabase
* PostgreSQL
* Supabase Auth
* Supabase Storage
* Supabase Realtime
* Supabase Edge Functions where necessary
* Geo-location services
* Payment integration/simulation
* AI demand forecasting

The primary application is a MOBILE APPLICATION.

---

# 1. ARCHITECTURE FIRST — ABSOLUTE RULE

NEVER start implementing a feature immediately after receiving a request.

Before writing code:

1. Understand the requested feature.
2. Understand why the feature exists in the product.
3. Inspect the current project structure.
4. Inspect related existing code.
5. Identify affected layers.
6. Identify affected database entities.
7. Identify authentication/authorization implications.
8. Identify state-management implications.
9. Identify navigation implications.
10. Identify API/backend implications.
11. Identify edge cases.
12. Identify how the feature interacts with existing features.
13. Decide where the feature belongs architecturally.
14. Only then implement it.

If the architecture is unclear, STOP and reason about the architecture before coding.

Never patch a feature into an inappropriate location just because it is faster.

---

# 2. UNDERSTAND THE ENTIRE SYSTEM BEFORE MAJOR IMPLEMENTATION

Before implementing major functionality, understand:

* Product requirements
* User roles
* Permissions
* Core workflows
* Database relationships
* Authentication flow
* Navigation architecture
* State management
* Repository/service architecture
* Error handling strategy
* Validation strategy
* Localization strategy
* Storage strategy
* Realtime requirements
* Security model

Maintain a mental model of the entire system.

A feature must fit into the existing architecture rather than creating an isolated mini-architecture.

---

# 3. READ THE LATEST OFFICIAL DOCUMENTATION

Before implementing ANY feature involving an external framework, SDK, package, API, or service:

READ THE CURRENT OFFICIAL DOCUMENTATION FIRST.

This includes, but is not limited to:

* Flutter
* Dart
* Supabase
* Supabase Flutter SDK
* PostgreSQL
* Supabase Auth
* Supabase Storage
* Supabase Realtime
* Supabase Edge Functions
* Maps APIs
* Payment APIs
* AI/ML APIs
* Any third-party Flutter package

Do not rely on:

* Memory
* Outdated tutorials
* Random blog posts
* Old Stack Overflow answers
* Deprecated APIs
* Deprecated packages
* Old GitHub examples

Prefer official documentation and official repositories.

When documentation has changed recently, follow the CURRENT recommended API and architecture.

If there is uncertainty about an API, verify it before coding.

---

# 4. NEVER INVENT APIs

NEVER assume that:

* A package has a particular method.
* A class exists.
* A parameter exists.
* A Supabase API behaves a certain way.
* A Flutter API still works.
* A package supports a particular platform.
* A package supports a particular version.

Verify it.

If you cannot verify an API, do not fabricate it.

---

# 5. STRICT TYPE SAFETY

Type safety is mandatory.

Use Dart's type system aggressively.

Rules:

* Avoid `dynamic`.
* Avoid `Object?` unless genuinely required.
* Avoid untyped maps where typed models are appropriate.
* Avoid stringly-typed business logic.
* Do not use magic strings for roles/statuses.
* Use enums or sealed types where appropriate.
* Use strongly typed models.
* Explicitly handle nullable values.
* Never use `!` casually.
* Avoid unsafe casts.
* Prefer compile-time guarantees over runtime assumptions.

Example:

BAD:

```dart
if (user.role == "admin") {}
```

Prefer a typed representation:

```dart
if (user.role == UserRole.cooperativeAdmin) {}
```

Database responses should be converted into typed domain models rather than passed through the application as arbitrary maps.

---

# 6. NULL SAFETY

Treat nullability as part of the architecture.

For every nullable value ask:

* Why can this be null?
* What should happen if it is null?
* Is null actually valid?
* Should the model be nullable?
* Should a default value exist?
* Should the operation fail safely?

Never silence null-safety problems simply to make compilation pass.

Avoid unnecessary:

```dart
value!
```

---

# 7. NO `any`-STYLE ESCAPES

Do not bypass the type system to move faster.

Avoid:

* `dynamic`
* unchecked casts
* giant `Map<String, dynamic>` objects
* arbitrary JSON passing between layers
* suppressing analyzer warnings
* ignoring compiler errors

If external JSON is untyped, parse it at the boundary into a typed model.

---

# 8. SEPARATION OF CONCERNS

Do not put everything inside widgets.

Flutter UI should NOT contain:

* Complex database queries
* Authentication logic
* Authorization logic
* Business rules
* Payment logic
* Complex data transformation
* Large validation systems

Prefer separation such as:

```text
Presentation
    ↓
State / Controller
    ↓
Repository
    ↓
Data Source
    ↓
Supabase
```

Keep responsibilities clear.

---

# 9. DATABASE ARCHITECTURE FIRST

Before modifying the database:

Understand:

* Existing schema
* Relationships
* Foreign keys
* Constraints
* Indexes
* RLS policies
* Authentication relationship
* Role model

Never create duplicate tables or fields because you failed to inspect the existing schema.

Prefer normalized relational design.

Use foreign keys and constraints where appropriate.

Do not treat PostgreSQL as a generic JSON store.

---

# 10. SECURITY IS NOT UI

NEVER consider the application secure merely because a button is hidden.

Authorization must be enforced at the backend/database level.

For every protected operation ask:

```text
Who is allowed to perform this?
```

Example:

```text
Customer
    → create booking

Worker
    → accept assigned booking

Cooperative Admin
    → verify workers belonging to their cooperative

Federation Admin
    → access federation-level analytics
```

Enforce permissions using appropriate Supabase security mechanisms such as RLS and backend validation.

Never trust:

* Client-provided role
* Client-provided user ID
* Client-provided ownership
* Client-provided payment status
* Client-provided verification status

---

# 11. RBAC MUST BE CENTRALIZED

Do not scatter role checks randomly across the UI.

Define a clear authorization model.

Use typed roles and permissions.

Example conceptual model:

```text
User
 ↓
Role
 ↓
Permissions
 ↓
Allowed Operations
```

The UI may hide unavailable actions for UX, but backend/database authorization remains mandatory.

---

# 12. VALIDATION

Validate data at the appropriate boundaries.

Validate:

* Forms
* User input
* API input
* Database operations
* File uploads
* Payment-related values
* Role-sensitive operations

Never assume frontend validation is sufficient.

---

# 13. ERROR HANDLING

Every external operation can fail.

Handle:

* Network errors
* Authentication errors
* Authorization errors
* Database errors
* Validation errors
* Timeout errors
* Storage errors
* Payment failures
* Missing data
* Invalid states

Never silently swallow exceptions.

Avoid:

```dart
catch (_) {}
```

Errors should be:

1. Captured
2. Classified
3. Logged appropriately
4. Converted into user-friendly states/messages

Do not expose internal database or server errors directly to users.

---

# 14. LOADING / EMPTY / ERROR STATES

Every asynchronous screen must consider:

```text
Loading
Success
Empty
Error
```

Do not design only the happy path.

For lists:

```text
Loading workers...
No workers found
Failed to load workers
Workers loaded
```

---

# 15. STATE MANAGEMENT

Before introducing state management:

Inspect the existing project.

Do not introduce multiple competing state-management solutions.

Use one consistent approach throughout the application.

Keep state:

* Predictable
* Typed
* Testable
* Scoped appropriately

Do not create global state for data that belongs locally to a screen.

---

# 16. NAVIGATION

Before adding a screen:

Understand the existing navigation architecture.

Consider:

* Authentication state
* User role
* Protected routes
* Deep links if applicable
* Back navigation
* Unauthorized access
* Navigation after mutations

Do not create navigation logic inside random widgets.

---

# 17. UI / UX

The application should feel like one coherent product.

Maintain consistency in:

* Typography
* Spacing
* Colors
* Buttons
* Cards
* Forms
* Icons
* Error states
* Loading states
* Navigation
* Empty states

Prefer reusable components over copy-pasting UI.

Do not over-engineer a design system for simple components, but avoid duplicated UI patterns.

---

# 18. MULTILINGUAL SUPPORT

The PS requires a multilingual mobile application.

Localization must be built into the architecture.

Do NOT hardcode user-facing strings throughout widgets.

Use localization resources.

Initial languages:

* English
* Hindi
* Marathi

Bad:

```dart
Text("Find Workers")
```

Prefer localized resources.

All important static UI strings should be localizable.

Do not blindly translate user-generated dynamic data.

---

# 19. FILE STORAGE

Worker documents and certifications are sensitive application data.

Before implementing uploads:

Consider:

* File type validation
* File size limits
* Storage paths
* Ownership
* Access permissions
* RLS/storage policies
* Secure retrieval

Do not expose private worker documents publicly without a deliberate security decision.

---

# 20. GEO-LOCATION

Location functionality must be privacy-conscious.

Only request location when necessary.

Handle:

* Permission denied
* Permission permanently denied
* Location unavailable
* GPS disabled
* Approximate location
* Network failure

Do not continuously track workers unless the product genuinely requires it.

For MVP, prefer:

```text
Customer location
    ↓
Find matching verified workers
    ↓
Distance calculation
    ↓
Sort/filter
```

---

# 21. PAYMENTS

For the hackathon MVP, payment may be simulated if real integration adds unnecessary risk.

Never fake security-sensitive payment state.

If a real payment gateway is used:

* Verify official documentation.
* Never trust client-side payment success alone.
* Keep secrets out of Flutter.
* Use backend verification/webhooks where required.

---

# 22. AI FEATURES

Do not introduce unnecessary AI complexity.

The AI requirement is:

```text
Historical bookings
        ↓
Demand analysis
        ↓
Demand forecast
        ↓
Workforce allocation recommendation
```

Build the simplest credible implementation that demonstrates the concept.

Do not build an elaborate ML pipeline if a lightweight forecasting prototype is sufficient.

---

# 23. HACKATHON PRIORITY

We have limited development time.

Prioritize:

1. Correct architecture
2. Working end-to-end flow
3. Core PS requirements
4. Security fundamentals
5. Good UX
6. Demo reliability
7. Optional enhancements

Do NOT sacrifice the core product to implement flashy features.

A complete working flow is more valuable than 30 incomplete screens.

---

# 24. NO PREMATURE ABSTRACTION

Do not create abstractions merely because they look architecturally sophisticated.

Avoid:

* Unnecessary generic repositories
* Excessive interfaces
* Over-engineered dependency injection
* Excessive folder nesting
* Unnecessary design patterns

Create abstractions when they solve an actual problem.

---

# 25. REUSE BEFORE CREATING

Before creating:

* A new widget
* A new utility
* A new service
* A new repository
* A new model
* A new helper

Search the codebase first.

If an existing abstraction can be reused or extended cleanly, use it.

Avoid duplicate implementations.

---

# 26. DEPENDENCY DISCIPLINE

Before adding a package:

1. Check whether Flutter/Dart already provides the functionality.
2. Check whether an existing project dependency already provides it.
3. Verify the package's current maintenance status.
4. Check compatibility with the project's Flutter/Dart version.
5. Read official documentation.
6. Only then add the dependency.

Do not add packages casually.

Every dependency increases maintenance and compatibility risk.

---

# 27. VERSION AWARENESS

Before implementation, inspect:

* Flutter version
* Dart version
* Existing package versions
* Supabase SDK version
* Platform requirements

Use APIs compatible with the project's actual versions.

Do not blindly copy code from documentation targeting another version.

---

# 28. TESTING

After implementing a feature:

1. Run formatter.
2. Run static analysis.
3. Run tests where applicable.
4. Fix warnings/errors.
5. Verify the feature manually.
6. Test important edge cases.

At minimum ensure:

```text
flutter analyze
```

passes without introducing new issues.

Do not declare a feature complete while the project has known compile errors.

---

# 29. MIGRATIONS

Database changes must be reproducible.

Do not manually change production-like database state without documenting the change.

Prefer migration files for schema changes.

A database change should be possible to recreate from a clean environment.

---

# 30. GIT DISCIPLINE

Keep changes focused.

Do not mix:

* Feature implementation
* Unrelated refactoring
* Random formatting
* Dependency upgrades
* Unrelated bug fixes

into one change unless necessary.

Preserve a clean history.

---

# 31. BEFORE EVERY FEATURE — INTERNAL CHECKLIST

Before coding:

```text
[ ] Do I understand the product requirement?
[ ] Do I understand the user journey?
[ ] Did I inspect the existing architecture?
[ ] Did I inspect related files?
[ ] Did I inspect the database schema?
[ ] Did I identify affected roles?
[ ] Did I identify authorization requirements?
[ ] Did I check the latest official documentation?
[ ] Did I verify package/API compatibility?
[ ] Did I identify edge cases?
[ ] Did I decide where the feature belongs?
```

Only after this should implementation begin.

---

# 32. AFTER EVERY FEATURE — COMPLETION CHECKLIST

Before declaring a feature complete:

```text
[ ] Code compiles
[ ] flutter analyze passes
[ ] Types are safe
[ ] No unnecessary dynamic usage
[ ] Null safety is handled
[ ] Loading state exists
[ ] Empty state exists where applicable
[ ] Error state exists
[ ] Authorization is enforced
[ ] Database security is considered
[ ] Localization is handled
[ ] Existing components are reused
[ ] No unnecessary dependencies were added
[ ] Manual flow was tested
[ ] No unrelated files were modified unnecessarily
```

---

# 33. WHEN REQUIREMENTS ARE AMBIGUOUS

Do not silently invent product behavior when the decision materially affects architecture or security.

If ambiguity is minor:

→ Choose the simplest reasonable behavior and document the assumption.

If ambiguity affects:

* Database schema
* Security
* Roles
* Payments
* User permissions
* Core workflow

→ Explain the ambiguity and resolve it before implementing.

---

# 34. NEVER TAKE SHORTCUTS THAT CREATE TECHNICAL DEBT

Do not use:

```text
temporary hardcoded IDs
fake production credentials
hardcoded roles
hardcoded user ownership
unprotected database operations
global mutable state
giant widgets
giant service classes
duplicate models
silent exception handling
```

A hackathon prototype can simplify functionality, but it must not have fundamentally broken architecture.

---

# 35. DEVELOPMENT PHILOSOPHY

Follow this sequence:

```text
UNDERSTAND
    ↓
INSPECT
    ↓
RESEARCH
    ↓
DESIGN
    ↓
IMPLEMENT
    ↓
VERIFY
    ↓
REFINE
```

NOT:

```text
REQUEST
  ↓
IMMEDIATELY CODE
  ↓
PATCH ERRORS
  ↓
PATCH MORE ERRORS
```

---

# 36. MOST IMPORTANT RULE

**Think before you code.**

The fastest implementation is not the one that produces code fastest.

The fastest implementation is the one that:

* Understands the architecture first
* Uses the correct APIs
* Uses the correct data model
* Reuses existing components
* Avoids rework
* Handles security correctly
* Maintains type safety
* Produces a complete working flow

Always optimize for **correctness + maintainability + development speed**, not raw lines of code.

You are building a coherent product, not a collection of screens.
