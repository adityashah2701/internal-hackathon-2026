# PS-089 — AUTHENTICATION + RBAC + ONBOARDING

Implement the **authentication and user onboarding foundation** for the PS-089 Flutter + Supabase monorepo.

Follow ALL existing agentic engineering rules already defined for this project.

Do not redesign the application or implement unrelated business features.

---

## 1. BEFORE CODING

First:

1. Inspect the current repository and architecture.
2. Inspect the existing Supabase setup.
3. Inspect existing dependencies and code.
4. Read the latest official Supabase Auth + Flutter documentation.
5. Understand the existing navigation/state-management approach.
6. Plan the authentication and onboarding flow before modifying files.

Do not duplicate existing infrastructure.

---

# 2. AUTHENTICATION

Implement Supabase Auth with:

* Email/password signup
* Email/password login
* Logout
* Persistent session handling
* Auth state changes
* Session restoration on app restart

Use the current recommended Supabase Flutter APIs.

Do not store passwords yourself.

Do not create a custom authentication system.

---

# 3. USER PROFILE + ROLE

Create the required database structure for application users.

Every authenticated user must have an application profile associated with their Supabase Auth user ID.

The profile should contain the minimum information required for onboarding and role handling.

Initial roles:

```text
customer
worker
cooperative_admin
federation_admin
```

Use a strongly typed representation in Dart.

Do not use arbitrary role strings throughout the application.

Do not trust a role supplied by the Flutter client.

---

# 4. ROLE-BASED ACCESS CONTROL

Implement proper RBAC architecture.

The flow should be:

```text
Supabase Auth
      ↓
Authenticated User
      ↓
Application Profile
      ↓
Role
      ↓
Role-specific permissions/navigation
```

The UI may hide/show features based on role, but this is NOT the security boundary.

Database operations must eventually be protected using Supabase Row Level Security.

Create appropriate RLS policies for the profile/role data being introduced.

Never allow a normal user to arbitrarily modify their own role.

Role changes must be controlled appropriately.

---

# 5. ONBOARDING FLOW

Add an onboarding flow between authentication and the main application.

Expected flow:

```text
App Launch
   ↓
Check Supabase Session
   ↓
Not authenticated → Login
   ↓
Authenticated
   ↓
Check Profile
   ↓
Profile missing/incomplete → Onboarding
   ↓
Profile complete → Role-based Home
```

The onboarding must prevent users from entering the main application without the minimum required profile information.

---

# 6. ROLE SELECTION

During signup/onboarding, handle role selection appropriately.

A user should be able to select a normal user role such as:

* Customer
* Worker

Administrative roles must NOT be freely selectable by anyone during public signup.

`cooperative_admin` and `federation_admin` should require controlled assignment/approval.

Do not create a security vulnerability where users can simply select an admin role.

---

# 7. PROFILE CREATION

Implement profile creation/update during onboarding.

At minimum support the information needed for the current identity/profile foundation, such as:

* Full name
* Phone number if required
* Role
* Profile completion status

Do not add worker-specific fields such as certifications, skills, documents, earnings, etc. yet.

Those belong to the Worker module.

---

# 8. NAVIGATION

Implement auth-aware and role-aware navigation.

Conceptually:

```text
                    App
                     ↓
              Session exists?
              /             \
            NO               YES
            ↓                 ↓
          Login          Profile exists?
                         /          \
                       NO            YES
                       ↓              ↓
                  Onboarding     Role-based Home
```

After onboarding:

```text
Customer          → Customer Home
Worker            → Worker Home
Cooperative Admin → Cooperative Dashboard
Federation Admin  → Federation Dashboard
```

For now, these destination screens can be minimal placeholders.

Do not design their actual dashboards yet.

---

# 9. AUTH STATE

Authentication state must be centralized and reactive.

The application should correctly handle:

* Initial session restoration
* Login
* Signup
* Logout
* Session expiry
* Auth state changes

Avoid manually maintaining duplicate authentication state that can become inconsistent with Supabase.

---

# 10. PROFILE COMPLETION

Define a clear mechanism for determining whether onboarding is complete.

Do not rely only on whether a Supabase Auth user exists.

The application needs to distinguish:

```text
Authenticated but onboarding incomplete
```

from:

```text
Authenticated and profile complete
```

---

# 11. DATABASE SECURITY

Use Supabase RLS.

At minimum ensure:

* Users can read their own profile.
* Users can update allowed profile fields.
* Users cannot change their own privileged role.
* Users cannot access another user's private profile data unless explicitly permitted.
* Administrative role assignment cannot be self-escalated.

Inspect the resulting policies carefully.

Do not blindly create permissive policies such as:

```text
authenticated users can do everything
```

---

# 12. TYPE SAFETY

Follow the project's strict type-safety rules.

Create typed models for:

* User profile
* Role
* Authentication state where appropriate

Avoid:

* `dynamic`
* arbitrary maps throughout the application
* unsafe casts
* unnecessary `!`
* magic role strings

Handle nullability explicitly.

---

# 13. ERROR / UX STATES

Authentication and onboarding must handle:

* Invalid credentials
* Existing email
* Weak password
* Network failure
* Session failure
* Profile creation failure
* Profile loading failure
* Unauthorized role
* Incomplete profile

Provide simple user-friendly error messages.

No elaborate UI design is required.

---

# 14. KEEP UI SIMPLE

Do NOT spend time on visual design.

Create only functional screens:

```text
Login
Signup
Onboarding
Role Selection
Basic Profile Form
Placeholder role-based Home screens
```

Use the existing theme/components if available.

Focus entirely on correct workflow and functionality.

---

# 15. DO NOT IMPLEMENT

Do NOT implement:

* Worker verification
* Skills
* Certifications
* Documents
* Booking
* Payments
* Maps
* Ratings
* Welfare
* Insurance
* AI
* Demand forecasting
* Notifications

Only prepare the authentication/profile/RBAC foundation required for those features later.

---

# 16. CODEBASE CLEANUP

While working, clean up repository clutter.

Inspect and remove unnecessary:

* Temporary files
* Generated test files that are no longer required
* Duplicate README files
* Default Flutter documentation that is no longer useful
* Temporary setup files
* Unused assets
* Unused imports
* Dead code

Do NOT delete anything without checking whether it is referenced.

Keep only useful project documentation.

---

# 17. README

Clean the root README so it represents the actual project.

It should briefly contain:

* Project name
* PS-089 description
* Tech stack
* Repository structure
* Local setup instructions
* Environment configuration
* Basic development commands

Do not create multiple redundant README files.

Keep documentation concise.

---

# 18. GITIGNORE AUDIT

Review `.gitignore` carefully.

Ensure it excludes appropriate:

* Flutter build artifacts
* IDE files
* OS files
* Generated files
* Local environment/configuration files containing secrets
* Supabase local development artifacts that should not be committed
* Temporary files

Do NOT blindly ignore source-controlled configuration that should be committed.

The goal is:

```text
git status
    ↓
Only meaningful source/configuration changes
```

Before finishing, inspect:

```bash
git status
```

and verify that no secrets, credentials, build artifacts, or temporary files are accidentally included.

---

# 19. VALIDATION

After implementation:

Run:

```bash
flutter analyze
flutter test
```

Build/run the application and manually verify:

```text
Signup
 ↓
Login
 ↓
Session persistence
 ↓
Profile creation
 ↓
Onboarding
 ↓
Role-based routing
 ↓
Logout
 ↓
Login again
 ↓
Correct role-based destination
```

Also verify that an unauthorized user cannot simply assign themselves an admin role.

---

# 20. FINAL REPORT

Report only:

### Implemented

* Authentication
* Profile
* RBAC
* Onboarding
* Navigation
* RLS

### Database

* Tables created/modified
* Important RLS policies

### Cleanup

* Files removed
* README changes
* `.gitignore` changes

### Validation

* `flutter analyze`
* `flutter test`
* Manual auth flow

### Next Step

Recommend the next logical PS-089 feature.

Do NOT automatically start implementing it.

---

# FINAL RULE

Follow the established engineering rules:

```text
INSPECT
→ READ CURRENT OFFICIAL DOCS
→ UNDERSTAND ARCHITECTURE
→ PLAN
→ IMPLEMENT
→ VERIFY
→ CLEAN UP
```

Do not over-engineer.

Do not redesign.

Do not implement unrelated features.

Prioritize **correct authentication, secure RBAC, complete onboarding workflow, clean repository structure, and a reliable foundation for the next feature.**
