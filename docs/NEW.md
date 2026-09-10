# Sahayog — Complete UI/UX Redesign & Workflow Refinement

You are working on the existing **Sahayog** Flutter mobile application for SIH PS-089.

The backend, authentication, RBAC, database structure, and many feature flows are already implemented. However, the current application feels like a collection of screens/buttons rather than a cohesive, production-quality mobile marketplace.

Your task is to perform a **complete UI/UX restructuring and refinement of the entire mobile application**.

Do NOT simply add more buttons or screens.

The final app should feel like a real, modern service marketplace such as a combination of **Urban Company + modern fintech/SaaS UX**, while still maintaining the identity of a **cooperative-owned platform**.

---

# 1. FIRST: INSPECT THE EXISTING APPLICATION

Before changing anything:

1. Inspect the complete `apps/mobile/lib/features` structure.
2. Inspect:

   * existing screens
   * widgets
   * routing
   * providers/controllers
   * repositories
   * models
   * Supabase integration
   * onboarding logic
   * authentication logic
   * role guards
   * existing theme
3. Understand which flows are already functional.
4. Reuse existing working logic wherever possible.
5. Do NOT duplicate existing repositories, models, services, or business logic.
6. Do NOT break existing authentication, RBAC, RLS, or database functionality.

The goal is:

> **Keep the backend/business functionality, completely improve how the user experiences it.**

---

# 2. CORE UX PRINCIPLE

The current application should NOT feel like:

> Screen → Button → Screen → Button

It should feel like:

> **Context → Information → Action → Confirmation → Progress → Result**

Every important action must provide:

* clear context
* obvious primary action
* loading state
* success state
* error state
* empty state
* progress/status feedback where applicable

Avoid unnecessary cards, excessive buttons, huge text blocks, and dashboard-like layouts everywhere.

Use meaningful hierarchy instead.

---

# 3. DESIGN DIRECTION

Create a modern premium mobile UI.

### Visual Direction

Use:

* Indigo / violet as primary brand colors
* Cool neutral backgrounds
* White / subtle tinted surfaces
* Strong typography hierarchy
* Rounded cards
* Soft borders
* Subtle shadows
* Modern icons
* Clean spacing
* Bottom sheets where appropriate
* Smooth transitions
* Meaningful micro-interactions

Avoid:

* Government-portal appearance
* Excessive green
* Huge empty areas
* Excessive gradients
* Excessive glassmorphism
* Too many cards
* Every element looking like a button
* Fake statistics
* Fake avatars
* Fake reviews
* Fake notifications
* Decorative elements that don't improve UX

Green should primarily represent:

* success
* verified
* completed
* positive status

---

# 4. IMPORTANT: WORKER PROFILE SETUP ARCHITECTURE

There is currently a UX problem:

After the worker completes profile setup, a separate profile-related experience still appears unnecessarily and the user gets confused about whether their profile setup is complete.

Fix this properly.

## Worker onboarding must include profile setup.

The worker should NOT have to complete profile information again after entering the main application.

### Desired Worker Flow

```text
Signup
   ↓
Authentication
   ↓
Worker Onboarding
   ↓
Basic Personal Information
   ↓
Worker Profile
   ↓
Skills / Trade
   ↓
Cooperative / Society
   ↓
Verification Documents
   ↓
Review & Submit
   ↓
Worker Home
```

The onboarding should collect everything required to create a usable worker profile.

---

# 5. WORKER PROFILE SETUP

Create a proper multi-step worker profile onboarding.

Keep each step simple.

## Step 1 — Personal Information

Collect:

* Full legal name
* Phone number
* Profile photo
* Primary district/location

Do not overload the screen.

---

## Step 2 — Professional Information

Collect:

* Primary trade
* Skills
* Years of experience
* Service categories
* Short professional introduction

Example:

> "Electrician with 6 years of residential wiring and appliance repair experience."

Keep the description optional if appropriate.

---

## Step 3 — Cooperative Affiliation

Collect/select:

* Cooperative
* Society
* Relevant local affiliation

The UI should clearly explain why this information is required.

Example:

> "Your cooperative verifies your professional credentials and helps ensure fair work opportunities."

---

# 6. DOCUMENT / VERIFICATION ONBOARDING

Worker verification should feel like a guided process, not an admin form.

Show:

```text
Profile
✓
Skills
✓
Cooperative
✓
Documents
○
Review
○
```

For each document:

* document name
* why it is required
* upload button
* uploaded state
* validation state
* retry/re-upload state

Never expose raw storage paths.

Do not show technical information such as SHA hashes to normal workers.

Those technical details can remain available to cooperative administrators.

---

# 7. PROFILE COMPLETION

Once the worker completes onboarding:

Show a clear confirmation screen:

> **Your worker profile is ready**

Then:

> "Your cooperative will review your documents before you can accept jobs."

Primary CTA:

**Go to Worker Home**

Do NOT send the user back into another profile setup screen.

---

# 8. WORKER BOTTOM NAVIGATION

After onboarding, the worker enters the main application shell.

Use a proper persistent bottom navigation.

## Worker Navigation

```text
Home
Jobs
Earnings
Notifications
Profile
```

The **Profile tab is NOT another profile setup flow.**

It should be the worker's actual profile/settings area.

---

# 9. WORKER PROFILE TAB

Create a polished worker profile page.

Example structure:

```text
[Profile Photo]

Rajesh Kumar
✓ Verified Worker

Electrician
Mumbai • Andheri

⭐ 4.8
124 Jobs
6 Years Experience

────────────────────

Professional Skills
• Residential Wiring
• Appliance Repair
• Electrical Maintenance

────────────────────

Cooperative
Andheri Electrical Cooperative

────────────────────

Verification
✓ Identity Verified
✓ Trade Verified
✓ Cooperative Verified

────────────────────

Account
Personal Information
Skills & Services
Documents
Availability
Notifications
Language
Help & Support
Logout
```

Do NOT make profile setup appear again.

If information is incomplete, show a small **Complete Profile** prompt only when genuinely necessary.

---

# 10. CUSTOMER BOTTOM NAVIGATION

Create:

```text
Home
Services
Bookings
Notifications
Profile
```

## Customer Home

The home screen should immediately answer:

> "What can I do here?"

Suggested structure:

```text
Good morning, [Name]

What service do you need?

[Search services]

Popular Services
Electrician
Plumber
Carpenter
AC Repair
Painting
Appliance Repair

Nearby verified professionals

Your Active Booking
```

Use real database data.

If there is no data:

Show meaningful empty states.

Never invent workers.

---

# 11. CUSTOMER SERVICE DISCOVERY

Service discovery should be a proper marketplace flow.

```text
Home
 ↓
Services
 ↓
Select Service
 ↓
Select Location
 ↓
Find Nearby Verified Workers
 ↓
Worker List
 ↓
Worker Profile
 ↓
Select Date & Time
 ↓
Review Booking
 ↓
Confirm Booking
```

Worker cards should display only real information:

* name
* trade
* verification status
* experience
* rating if enough real reviews exist
* distance
* availability

Do NOT show fake ratings or fake worker profiles.

---

# 12. LOCATION UX

Integrate location naturally into the customer experience.

The customer should be able to:

* use current location
* select saved address
* add a new address
* manually enter location

Worker matching should consider:

1. service/skill
2. verification status
3. availability
4. supported region
5. distance

Do not create fake map markers.

If no nearby worker exists:

> **No verified workers found nearby**

Then provide:

* change location
* choose another time
* browse other services

---

# 13. CUSTOMER BOOKINGS

Create a proper booking section.

Tabs/filters:

```text
Upcoming
Active
Completed
Cancelled
```

Each booking should have:

* service
* worker
* scheduled time
* location
* current status
* price
* booking ID

Tap booking → detailed booking timeline.

---

# 14. BOOKING TIMELINE

The booking detail screen should clearly show progress.

Example:

```text
Booking #SHY-1024

AC Repair
Rajesh Kumar

✓ Request Sent
✓ Worker Accepted
✓ Worker Scheduled
● Worker On The Way
○ Worker Arrived
○ Job Started
○ Job Completed
○ Payment
○ Review
```

The current step must be visually emphasized.

Do not simply show status as text.

---

# 15. WORKER JOB EXPERIENCE

Worker Jobs should have:

```text
New Requests
Active
Completed
```

A job request should clearly display:

* service
* customer location
* distance
* scheduled time
* estimated earning
* emergency status
* relevant customer instructions

Primary action:

**Accept Job**

Secondary:

**Decline**

Avoid multiple competing CTAs.

---

# 16. WORKER ACTIVE JOB

After accepting a job, do NOT leave the worker on a generic page with random buttons.

Create a guided job progression.

```text
Accepted
   ↓
Scheduled
   ↓
On The Way
   ↓
Arrived
   ↓
OTP Verification
   ↓
Job In Progress
   ↓
Complete Job
   ↓
Payment Pending
   ↓
Paid
```

Each state should have:

* current status
* next action
* contextual information
* timeline
* location information when relevant

Only show actions valid for the current state.

---

# 17. ARRIVAL + OTP

When worker reaches the customer:

Show:

> **Confirm customer arrival**

Customer receives a real OTP.

Worker enters the OTP.

Never hardcode something like:

```text
1234
```

The OTP must come from the actual backend flow.

After successful verification:

```text
Job Started
```

Both customer and worker should see the updated status.

Use Supabase Realtime where appropriate.

---

# 18. JOB COMPLETION

Completion should not simply be:

> [Complete Job]

Instead:

```text
Job Summary

Service
Duration
Additional approved charges
Total amount

[Mark Job Complete]
```

After completion:

```text
Job Completed

Payment required
₹XXX

[Proceed to Payment]
```

---

# 19. PAYMENT UX

Integrate the actual payment flow using Razorpay safely.

Customer flow:

```text
Job Completed
 ↓
Payment Summary
 ↓
Razorpay Checkout
 ↓
Payment Verification
 ↓
Payment Success
 ↓
Invoice
 ↓
Rating
```

Never trust payment success based only on client-side callbacks.

Payment verification must happen server-side.

Do not expose Razorpay secret keys in Flutter.

Use Supabase Edge Functions/backend verification and webhooks where appropriate.

---

# 20. INVOICE

After successful payment:

Show a professional invoice screen.

Include:

* invoice ID
* booking ID
* service
* worker
* date
* base amount
* welfare contribution
* total paid
* payment status

Provide an option to view/share/download the invoice if already supported by the architecture.

---

# 21. RATINGS & REVIEWS

After successful completion/payment:

Show:

> **How was your experience?**

Allow:

* star rating
* optional comment

Only allow eligible users to review the booking.

One booking = one review.

No fake reviews.

If there are no reviews:

Do not display:

> 4.8 ⭐

unless that value actually exists in the database.

---

# 22. WORKER EARNINGS

Worker Earnings should be a real financial view.

Example:

```text
This Month

₹24,500
Earned

12 Jobs

Pending
₹2,000

Available
₹22,500
```

Below:

```text
Recent Earnings

AC Repair       ₹1,200
Electrician     ₹800
Plumbing        ₹950
```

All values must come from real completed/paid bookings.

If there is no data:

> No earnings yet

Do not show fake numbers.

---

# 23. NOTIFICATIONS

Notifications must be event-driven.

Examples:

Customer:

* Worker accepted your booking
* Worker is on the way
* Worker has arrived
* Payment successful
* Invoice generated

Worker:

* New job request
* Booking accepted
* Job reminder
* Payment received
* Verification approved/rejected

Cooperative:

* New worker verification request
* New document submitted
* Booking requiring attention

Do not preload fake notifications.

Use empty state:

> You're all caught up.

---

# 24. COOPERATIVE UI

The cooperative application should feel like an operational workspace rather than a generic dashboard.

Bottom navigation:

```text
Dashboard
Verification
Workers
Jobs
Profile
```

## Dashboard

Show only real metrics:

* Active Workers
* Pending Verification
* Active Jobs
* Completed Jobs
* Welfare Pool

If there is no data:

```text
0
```

is completely acceptable.

Do not fabricate activity.

---

# 25. COOPERATIVE VERIFICATION

Create a clear verification queue.

```text
Pending
Approved
Rejected
```

Worker verification detail:

```text
Worker
Trade
Cooperative

Documents
✓ Identity
✓ Trade Certificate
✓ Membership

Verification History

[Approve]
[Reject]
```

Reject must require a reason.

After approval:

Worker status updates immediately.

Worker should automatically move from verification state → Worker Home when appropriate.

---

# 26. FEDERATION UI

Bottom navigation:

```text
Overview
Cooperatives
Workforce
Analytics
Profile
```

Keep this role focused on high-level operations.

Show real aggregated data.

Examples:

* Registered Workers
* Verified Workers
* Active Cooperatives
* Jobs Completed
* Welfare Contribution

No fake graphs.

If there isn't enough historical data:

> Not enough data for forecasting yet.

This is preferable to fabricated AI insights.

---

# 27. RESPONSIVE STATES

Every major screen must handle:

### Loading

Use skeletons/progress indicators where appropriate.

### Empty

Example:

> No bookings yet
> Your upcoming services will appear here.

### Error

Example:

> Something went wrong
> We couldn't load your bookings.

CTA:

**Try Again**

### Success

Use confirmation feedback.

### Offline / Network Failure

Show useful retry messaging instead of silently failing.

---

# 28. NAVIGATION ARCHITECTURE

Use one consistent application shell per role.

Example:

```text
Authenticated User
        ↓
Role Resolver
        ↓
┌───────────────┐
│ Customer      │ → CustomerShell
│ Worker        │ → WorkerShell
│ Cooperative   │ → CooperativeShell
│ Federation    │ → FederationShell
└───────────────┘
```

Bottom navigation should remain persistent within the role.

Do NOT push users through unnecessary screens.

Deep-link into details when appropriate.

Back navigation must behave naturally.

---

# 29. REMOVE REDUNDANT SCREENS

While implementing the redesign, identify:

* duplicate profile screens
* duplicate onboarding
* unnecessary verification pages
* dead-end screens
* screens containing only one button
* duplicate navigation
* confusing redirects
* redundant forms

Remove or merge them where appropriate.

Do NOT keep a screen just because it already exists.

The goal is a simpler application.

---

# 30. MICRO-INTERACTIONS

Add subtle interactions where they improve usability:

* page transitions
* bottom-sheet transitions
* status changes
* success confirmations
* button loading states
* verification completion
* booking progress
* payment success
* pull-to-refresh where useful

Avoid excessive animations.

---

# 31. REAL DATA ONLY

This rule is absolute.

Do NOT create:

* fake workers
* fake customers
* fake ratings
* fake earnings
* fake bookings
* fake notifications
* fake analytics
* fake map markers
* fake payment success
* fake AI predictions

If the database has no records:

**show an honest empty state.**

---

# 32. DATABASE / BUSINESS LOGIC SAFETY

Do not move business logic into widgets just to make UI work.

Maintain:

```text
Presentation
 ↓
Controller / State
 ↓
Repository
 ↓
Data Source
 ↓
Supabase
```

UI should consume proper typed models/state.

Do not introduce:

```dart
Map<String, dynamic>
```

everywhere as a shortcut.

Avoid:

* duplicated logic
* magic strings
* unnecessary dependencies
* hardcoded IDs
* hardcoded statuses
* hardcoded OTP
* hardcoded prices

---

# 33. STATE-DRIVEN UI

The UI must be driven by actual domain state.

For example:

```text
BookingStatus.REQUESTED
BookingStatus.ACCEPTED
BookingStatus.ON_THE_WAY
BookingStatus.ARRIVED
BookingStatus.IN_PROGRESS
BookingStatus.COMPLETED
BookingStatus.PAYMENT_PENDING
BookingStatus.PAID
BookingStatus.REVIEWED
```

Render actions based on state.

Example:

```text
REQUESTED
→ Accept / Decline

ACCEPTED
→ Start Travel

ON_THE_WAY
→ Confirm Arrival

ARRIVED
→ Enter OTP

IN_PROGRESS
→ Complete Job

COMPLETED
→ Payment

PAID
→ Review
```

The user must never see invalid actions.

---

# 34. LOCALIZATION

Keep the application localization-ready.

Initial languages:

* English
* Hindi
* Marathi

Do not hardcode user-facing strings throughout widgets.

Centralize strings appropriately.

---

# 35. ACCESSIBILITY

Ensure:

* readable text sizes
* sufficient contrast
* touch targets are large enough
* icons have semantic meaning
* important information isn't communicated by color alone

---

# 36. FINAL USER JOURNEYS TO TEST

After implementation, manually test these complete journeys.

## Customer Journey

```text
Signup
→ Customer Onboarding
→ Home
→ Services
→ Select Service
→ Location
→ Nearby Workers
→ Worker Profile
→ Date/Time
→ Booking Confirmation
→ Booking Timeline
→ Worker Accepted
→ Worker On The Way
→ Worker Arrived
→ Job Started
→ Job Completed
→ Payment
→ Invoice
→ Rating
```

## Worker Journey

```text
Signup
→ Worker Onboarding
→ Personal Profile
→ Skills
→ Cooperative
→ Documents
→ Submit Verification
→ Verification Pending
→ Cooperative Approval
→ Worker Home
→ New Job Request
→ Accept
→ Scheduled
→ On The Way
→ Arrived
→ OTP
→ Job Started
→ Complete
→ Payment Received
→ Earnings Updated
```

## Cooperative Journey

```text
Login
→ Dashboard
→ Verification Queue
→ Worker
→ Documents
→ Approve
→ Worker Becomes Verified
→ Workers List
→ Jobs
→ Real-time Updates
```

## Federation Journey

```text
Login
→ Overview
→ Cooperatives
→ Workforce
→ Analytics
→ Real Aggregated Data
```

---

# 37. QUALITY BAR

Before finishing:

### Run

```bash
flutter analyze
flutter test
```

Fix all errors and warnings.

Verify:

* authentication still works
* RBAC still works
* onboarding works
* worker profile setup happens only once
* worker approval redirects correctly
* bottom navigation works
* customer booking works
* worker job lifecycle works
* OTP works
* payment flow works
* realtime updates work
* invoice works
* ratings work
* earnings update
* cooperative verification works
* federation analytics use real data

---

# 38. MOST IMPORTANT UX REQUIREMENT

The application should feel like a **single coherent product**, not four unrelated dashboards.

Every screen should answer:

1. Where am I?
2. What is happening?
3. What can I do next?
4. What happens after I do it?

If a screen does not answer these questions, redesign it.

---

# 39. DO NOT DO THIS

Do NOT:

* rewrite the backend unnecessarily
* replace Supabase
* introduce unnecessary libraries
* create fake data
* create fake APIs
* hardcode production values
* add random buttons
* duplicate profile setup
* make admin roles selectable by normal users
* break RLS
* bypass backend payment verification
* create fake maps
* create fake AI predictions
* add unnecessary animations
* turn every screen into a dashboard

---

# 40. FINAL OBJECTIVE

Transform the current Sahayog application from:

> **"A technically functional prototype with many screens"**

into:

> **"A believable, polished, production-style cooperative service marketplace."**

The user should be able to open the application and intuitively understand what to do without needing an explanation.

Prioritize:

**Clarity > features**

**Real state > decoration**

**User flow > number of screens**

**Consistency > complexity**

**Real data > fake demo content**

**Trust > flashy UI**

Implement the redesign systematically, reusing existing functionality wherever possible, and verify the complete end-to-end experience before considering the task complete.
