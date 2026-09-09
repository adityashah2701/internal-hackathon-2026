# PS-089 — TAKE THE APPLICATION TO THE NEXT LEVEL

The current PS-089 implementation already has:

* Flutter + Supabase foundation
* Supabase Auth
* RBAC
* Onboarding
* Profiles
* Worker verification
* Worker documents
* Cooperative portal
* Federation portal
* Initial bookings/welfare schema
* RLS
* Clean empty states
* 48 passing tests
* No intentional dummy data

Now take the application from the current foundation to a **complete, scalable, end-to-end product architecture**.

Follow ALL existing agentic engineering rules strictly.

---

# 1. CRITICAL RULE — PLAN BEFORE IMPLEMENTING

DO NOT immediately start creating screens or tables.

First inspect the entire current codebase and Supabase migrations.

Then understand:

* Existing architecture
* Existing tables
* Existing relationships
* Existing RLS
* Existing navigation
* Existing repositories
* Existing models
* Existing auth/RBAC
* Existing booking/welfare implementation
* Existing tests

Then design the **complete target architecture** for the entire PS-089 application.

Before making major changes, produce a concise implementation plan covering:

1. Final database schema
2. Entity relationships
3. RLS/security model
4. Complete user journeys
5. Application modules
6. Payment architecture
7. GPS/location architecture
8. Worker matching
9. Notifications
10. Welfare/insurance
11. AI forecasting
12. Scalability strategy
13. Implementation order

Do not implement a feature until you understand how it fits into the complete system.

---

# 2. NO DUMMY DATA — ABSOLUTE RULE

DO NOT add fake/demo data anywhere.

This includes:

* Workers
* Customers
* Bookings
* Ratings
* Payments
* Earnings
* Analytics
* Cooperatives
* Federation statistics
* Locations
* Documents
* AI predictions
* Reviews

If the database has no data, show a proper empty state.

Examples:

```text
No workers available nearby.
```

```text
No bookings yet.
```

```text
No analytics data available.
```

Never fabricate numbers to make the UI look complete.

Use real Supabase data only.

For development/testing, test fixtures may exist ONLY inside automated tests and must never appear in the production application.

---

# 3. FINAL DOMAIN ARCHITECTURE

Design the complete domain model before extending the database.

The final system should conceptually support:

```text
Federation
   │
   └── Cooperatives
          │
          └── Workers
                 │
                 ├── Skills
                 ├── Certifications
                 ├── Documents
                 ├── Availability
                 ├── Location
                 └── Welfare/Insurance

Customers
   │
   └── Bookings
          │
          ├── Worker
          ├── Cooperative
          ├── Payment
          ├── Invoice
          └── Review
```

Make the actual relational design cleaner where appropriate.

---

# 4. COMPLETE DATABASE SCHEMA

Inspect existing migrations first.

Do NOT duplicate tables that already exist.

Extend the existing schema using new migration files.

Design the complete PostgreSQL schema required by the application.

Potential entities include:

```text
profiles
cooperatives
federations
worker_profiles
worker_skills
skills
certifications
worker_documents
worker_availability
worker_locations
service_categories
services
bookings
booking_status_history
payments
invoices
reviews
welfare_contributions
insurance_policies
emergency_requests
notifications
```

You may introduce additional entities if architecturally necessary.

For each entity define:

* Primary key
* Foreign keys
* Required fields
* Nullable fields
* Constraints
* Indexes
* Timestamps
* Ownership
* Status enums where appropriate

Avoid over-normalization.

Avoid giant JSON columns when relational structure is more appropriate.

---

# 5. DATABASE RELATIONSHIPS

Ensure relationships correctly represent:

```text
Federation
   ↓
Cooperative
   ↓
Worker
```

and:

```text
Customer
   ↓
Booking
   ↓
Worker
   ↓
Cooperative
```

Also support:

```text
Booking
 ├── Payment
 ├── Invoice
 ├── Welfare Contribution
 ├── Status History
 └── Review
```

Use foreign keys and database constraints to maintain integrity.

---

# 6. RLS / SECURITY

Review all existing RLS policies before adding new ones.

Implement a complete authorization model.

Examples:

### Customer

Can:

* Read available verified workers
* Create their own bookings
* Read their own bookings
* Pay for their own bookings
* Review completed bookings they own

Cannot:

* Modify another customer's bookings
* Modify worker verification
* Modify payment state
* Modify roles

### Worker

Can:

* Read their own profile
* Update allowed profile fields
* Manage their availability
* View assigned/eligible jobs
* Update their own job status where permitted
* View their own earnings

Cannot:

* Approve themselves
* Modify verification status
* Modify payment records
* Access another worker's private documents

### Cooperative Admin

Can:

* Manage workers belonging to their cooperative
* Verify/reject worker documents
* View cooperative bookings
* View cooperative-level analytics

Cannot:

* Manage unrelated cooperatives
* Escalate themselves to federation admin

### Federation Admin

Can:

* View state/federation-wide aggregated information
* Manage authorized cooperative relationships
* View workforce analytics

Enforce security in PostgreSQL/Supabase.

Frontend role checks are NOT sufficient.

---

# 7. SERVICE CATALOG

Implement a real service catalog backed by Supabase.

Do not hardcode the service marketplace into Flutter widgets.

Structure it around:

```text
Service Category
      ↓
Service
      ↓
Required Skills
```

Examples may include:

* Electrician
* Plumber
* Carpenter
* Painter
* AC Service
* Appliance Repair
* Cleaning
* Gardening
* Caregiving
* Driver

These should come from the database.

Do not insert fake worker records just because services exist.

---

# 8. GPS / GEO-LOCATION

Implement real location functionality.

The customer should be able to use their current location or provide a service location.

Worker profiles should support location information appropriate for matching.

Do NOT continuously track workers unless required.

For MVP:

```text
Customer location
       ↓
Find verified workers
       ↓
Filter by required skill/service
       ↓
Filter by availability
       ↓
Calculate distance
       ↓
Sort by relevance/distance
```

Use a proper geo-location strategy.

Prefer PostgreSQL/PostGIS if supported and appropriate for the Supabase project.

Do not calculate everything inefficiently on the client if the dataset grows.

Create appropriate indexes for geo queries.

---

# 9. WORKER MATCHING

Create a scalable matching strategy.

Initial ranking can consider:

1. Required skill
2. Verified status
3. Availability
4. Geographic distance
5. Worker rating where sufficient real data exists
6. Cooperative affiliation

Do NOT fabricate ratings or ranking scores.

If rating data does not exist, simply omit that factor.

Keep matching logic centralized so it can later support AI-based allocation.

---

# 10. BOOKING LIFECYCLE

Complete the booking lifecycle.

Recommended:

```text
Requested
    ↓
Accepted
    ↓
Scheduled
    ↓
In Progress
    ↓
Completed
    ↓
Payment Confirmed
    ↓
Reviewed
```

Also support appropriate:

```text
Rejected
Cancelled
Expired
```

Define valid state transitions.

Do not allow arbitrary client-side status changes.

Status transitions should be validated server-side.

Maintain booking status history for auditing.

---

# 11. EMERGENCY / ON-DEMAND SERVICE

Implement emergency booking as a variation of the normal booking flow.

Example:

```text
Emergency
   ↓
Find available nearby verified workers
   ↓
Prioritize distance + availability
   ↓
Create urgent booking
```

Do not create fake "45 minute guaranteed" claims unless the system can genuinely support that guarantee.

If the emergency fee is configurable, store it in a proper configuration/service structure rather than hardcoding it across the UI.

---

# 12. PAYMENT ARCHITECTURE

Implement payment integration carefully.

First understand the latest official documentation for the chosen payment provider.

For India, evaluate **Razorpay** as the primary option.

Architecture:

```text
Customer
   ↓
Booking
   ↓
Payment Order
   ↓
Payment Gateway
   ↓
Server-side verification
   ↓
Payment confirmed
   ↓
Invoice
   ↓
Welfare contribution
   ↓
Worker/cooperative earnings
```

IMPORTANT:

Never trust client-side payment success alone.

Never place payment secret keys in Flutter.

Secrets must remain server-side.

Use Supabase Edge Functions or an appropriate secure backend mechanism for:

* Creating payment orders
* Verifying payment signatures
* Processing webhooks
* Updating payment state

Use the current official Razorpay documentation before implementation.

If full gateway integration creates unacceptable hackathon risk, implement a clean payment abstraction and a clearly defined sandbox/test flow — but do not fabricate successful real-world transactions.

---

# 13. INVOICING

Create real invoice records based on actual bookings/payments.

Invoice should conceptually contain:

```text
Invoice
 ├── Booking
 ├── Customer
 ├── Worker
 ├── Service
 ├── Base amount
 ├── Welfare contribution
 ├── Total
 ├── Payment status
 └── Timestamp
```

Do not hardcode invoices.

---

# 14. WELFARE MODEL

Implement the cooperative welfare contribution correctly according to the product model.

Do not simply display a fake "5%" number everywhere.

Centralize the contribution logic.

For every completed/paid booking:

```text
Gross Service Amount
        ↓
Welfare Contribution
        ↓
Worker / Cooperative Settlement
```

Make the percentage configurable through an appropriate backend configuration rather than scattering `0.05` throughout Flutter code.

Ensure monetary calculations use appropriate precision and avoid floating-point errors.

---

# 15. WORKER EARNINGS

Worker earnings must be derived from real completed/paid bookings.

Do not store arbitrary dashboard totals.

Use real transactional data or secure server-side aggregation.

Example:

```text
Completed Jobs
      ↓
Eligible Earnings
      ↓
Welfare Deduction
      ↓
Worker Earnings
```

---

# 16. WORKER WELFARE / INSURANCE

Implement the architecture for worker welfare and insurance.

Do not build a fake insurance provider.

At MVP level, support:

* Welfare eligibility/status
* Contribution history
* Insurance enrollment/status if applicable

Keep external insurance integration abstract so a real provider can be added later.

---

# 17. RATINGS & REVIEWS

Implement reviews using real completed bookings.

Rules:

* Customer can review their own completed booking.
* One review per eligible booking.
* Worker cannot review themselves.
* Ratings must be validated.
* Review ownership must be enforced with RLS.

Do not show rating statistics until real reviews exist.

---

# 18. NOTIFICATIONS

Prepare a scalable notification architecture.

Potential events:

* Booking requested
* Booking accepted
* Booking rejected
* Booking cancelled
* Worker verification approved
* Worker verification rejected
* Payment successful
* Job completed

Do not create fake notifications.

Only generate notifications from actual events.

For the initial implementation, prioritize in-app notifications if push notification setup would slow down the core flow.

---

# 19. AI DEMAND FORECASTING

Implement the AI requirement only after the real booking data pipeline exists.

Architecture:

```text
Real Booking History
       ↓
Service/District Aggregation
       ↓
Demand Forecast
       ↓
Expected Demand
       ↓
Current Workforce
       ↓
Allocation Recommendation
```

Do NOT fabricate historical data to make AI appear to work.

If insufficient real data exists, show:

```text
Insufficient booking data for forecast.
```

rather than fake predictions.

Design the forecasting service so it can later be replaced by a more sophisticated model.

---

# 20. FEDERATION ANALYTICS

All federation metrics must be calculated from real Supabase data.

Examples:

* Total workers
* Verified workers
* Pending verification
* Active cooperatives
* Completed jobs
* Total service value
* Welfare contributions

If there is no data:

```text
0
```

or an appropriate empty state.

Never insert dummy numbers.

---

# 21. SCALABILITY

Design for growth from the beginning.

Consider:

* PostgreSQL indexes
* Geo indexes
* Pagination
* Query limits
* Efficient joins
* Server-side aggregation
* RLS performance
* Storage access
* Realtime subscriptions
* Notification volume
* Payment webhooks
* Idempotency
* Audit history

Do not fetch entire tables into Flutter.

Do not perform expensive global filtering on the client.

Use server-side queries for scalable operations.

---

# 22. PAGINATION

All potentially large datasets must be designed for pagination.

Especially:

* Workers
* Bookings
* Documents
* Notifications
* Federation workforce registry
* Verification queue

Do not load thousands of rows into memory.

---

# 23. OFFLINE / NETWORK RESILIENCE

The app should gracefully handle temporary network failures.

Do not claim offline support unless it is actually implemented.

At minimum:

* Show connection errors
* Allow retry
* Avoid losing form state unnecessarily
* Prevent duplicate submissions

For payments/bookings, think carefully about idempotency.

---

# 24. ARCHITECTURE CONSISTENCY

Continue using the existing clean architecture.

Maintain:

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

Business rules should not live inside widgets.

Payment logic should not live inside widgets.

Matching logic should not live inside widgets.

Authorization should not live only inside widgets.

---

# 25. TYPE SAFETY

Continue strict Dart type safety.

Use typed:

* Models
* Enums
* Booking statuses
* Payment statuses
* Verification statuses
* Roles
* Domain results/errors

Avoid:

```text
dynamic
Map<String, dynamic> everywhere
magic strings
unsafe casts
unnecessary !
```

If possible, generate strongly typed database models/types from the actual Supabase schema rather than manually duplicating database definitions indefinitely.

---

# 26. DATABASE MIGRATIONS

Do NOT modify the database manually without a migration.

Every schema change must be reproducible.

Use sequential migrations.

Before adding a migration:

* Inspect existing migrations
* Avoid duplicate definitions
* Consider migration ordering
* Add constraints
* Add indexes
* Add RLS
* Test policies

---

# 27. TESTING

Expand the existing test suite as features are added.

Prioritize tests for:

* Booking state transitions
* Worker matching
* Distance filtering
* RBAC
* RLS-sensitive operations
* Payment verification
* Welfare calculations
* Invoice generation
* Review ownership
* Emergency booking
* Profile permissions

Do not sacrifice correctness for speed.

---

# 28. UI PRINCIPLE

Keep the current modern aesthetic.

Do NOT fill the application with cards simply to make it look complete.

Every screen should represent actual functionality.

Use:

```text
Real data
OR
Intentional empty state
```

Never:

```text
Real data
OR
Fake data
```

---

# 29. IMPLEMENTATION ORDER

After planning the complete architecture, implement in this order:

### Phase 1 — Data foundation

* Finalize schema
* Migrations
* Relationships
* RLS
* Indexes

### Phase 2 — Marketplace

* Service catalog
* Worker discovery
* GPS
* Filtering
* Matching

### Phase 3 — Booking

* Booking creation
* Scheduling
* Worker acceptance
* Status lifecycle
* Emergency flow

### Phase 4 — Financial flow

* Payment abstraction
* Razorpay sandbox/integration
* Payment verification
* Invoices
* Welfare contribution
* Worker earnings

### Phase 5 — Trust & communication

* Ratings
* Reviews
* Notifications
* Worker welfare/insurance

### Phase 6 — Federation intelligence

* Real analytics
* Demand forecasting
* Workforce allocation

### Phase 7 — Polish

* Loading states
* Empty states
* Error handling
* Localization
* Performance
* Accessibility

Do not jump directly to AI before the real data pipeline exists.

---

# 30. GIT / REPOSITORY CLEANLINESS

Continue maintaining a clean repository.

Do not commit:

* Secrets
* Environment credentials
* Build artifacts
* Temporary files
* Debug dumps
* Generated junk
* Unnecessary documentation
* Fake seed data

Keep `.gitignore` accurate.

Before major milestones:

```bash
git status
```

Review the complete diff.

---

# 31. DOCUMENTATION

Update concise architecture documentation as the system grows.

Document:

* Final architecture
* Database relationships
* RBAC model
* Booking lifecycle
* Payment lifecycle
* GPS/matching strategy
* Welfare calculation
* AI strategy

Documentation should describe the **actual implemented system**, not future claims.

---

# 32. IMPORTANT PRODUCT INTEGRITY RULE

Never claim a feature is implemented if it is only represented visually.

For example:

If GPS matching works → say GPS matching.

If payment sandbox works → say payment sandbox.

If AI forecasting has insufficient data → show insufficient data.

If insurance is only an architecture → do not present it as a fully integrated insurance system.

The application must remain technically honest.

---

# 33. FINAL QUALITY BAR

The final application should support a real end-to-end journey:

```text
CUSTOMER
   ↓
Select Service
   ↓
Use Location
   ↓
Find Verified Nearby Workers
   ↓
Select Worker
   ↓
Schedule / Emergency Booking
   ↓
Booking Created
   ↓
WORKER
   ↓
Accept
   ↓
Start Job
   ↓
Complete Job
   ↓
CUSTOMER
   ↓
Payment
   ↓
Invoice
   ↓
Welfare Contribution
   ↓
Rating / Review
   ↓
FEDERATION
   ↓
Real Analytics
   ↓
Demand Forecast
   ↓
Workforce Allocation
```

All of this must operate on **real Supabase data**.

---

# ABSOLUTE RULES

1. **No dummy data.**
2. **No fake analytics.**
3. **No fake payments.**
4. **No fake AI predictions.**
5. **No hardcoded marketplace data where database-backed data is appropriate.**
6. **Read current official documentation before integrating external services.**
7. **Inspect existing architecture before modifying it.**
8. **Plan the complete architecture before implementing major features.**
9. **Maintain strict type safety.**
10. **Enforce authorization at the database/backend level.**
11. **Use migrations for database changes.**
12. **Do not over-engineer.**
13. **Do not break existing functionality.**
14. **Do not create unnecessary packages or services.**
15. **Every feature must fit into the overall architecture.**

Follow:

```text
INSPECT
   ↓
UNDERSTAND
   ↓
RESEARCH CURRENT DOCS
   ↓
DESIGN COMPLETE ARCHITECTURE
   ↓
MIGRATE DATABASE
   ↓
IMPLEMENT INCREMENTALLY
   ↓
TEST
   ↓
VERIFY REAL DATA FLOW
   ↓
POLISH
```

Do not optimize for the number of screens.

Optimize for a **real, secure, scalable, end-to-end cooperative marketplace that can be demonstrated reliably.**
