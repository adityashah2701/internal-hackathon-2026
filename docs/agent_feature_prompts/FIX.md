# PS-089 — PRODUCT UX + REAL END-TO-END FLOW REWORK

The current application has functional pieces, but it does NOT yet feel like a real service marketplace.

There are too many buttons/screens without a coherent product journey.

The application currently feels like a collection of features rather than a real consumer/service platform.

Your task now is to **rework the existing application around a realistic, production-like user experience and complete the actual end-to-end service lifecycle.**

Follow ALL existing agentic engineering rules.

Do NOT add random demo content.

Do NOT use dummy data.

Do NOT redesign only individual screens.

Think about the entire product journey first.

---

# 1. FIRST — UNDERSTAND THE CURRENT APPLICATION

Before changing anything:

Inspect:

* Current navigation
* Current authentication
* Onboarding
* Customer screens
* Worker screens
* Cooperative screens
* Federation screens
* Booking implementation
* Database schema
* RLS
* Existing repositories
* Existing models
* Existing tests
* Existing Supabase integration

Identify why the current experience feels disconnected.

Then create a concise plan for restructuring the UX.

Do not start coding immediately.

---

# 2. PRIMARY PRODUCT GOAL

The application should feel like a real local service marketplace.

The core experience is:

```text id="4ajf9x"
Customer needs a service
        ↓
Selects service
        ↓
Enters / uses location
        ↓
Sees nearby verified workers
        ↓
Chooses worker
        ↓
Chooses date/time
        ↓
Confirms booking
        ↓
Worker receives request
        ↓
Worker accepts
        ↓
Both see booking status
        ↓
Worker arrives
        ↓
OTP verification
        ↓
Job starts
        ↓
Job completed
        ↓
Customer payment
        ↓
Invoice
        ↓
Rating
```

This must become the backbone of the application.

---

# 3. BOTTOM TAB NAVIGATION

Implement proper role-specific bottom navigation.

The application should NOT feel like a collection of buttons leading to unrelated pages.

## CUSTOMER

Use something similar to:

```text id="1qf6v2"
Home
Services
Bookings
Notifications
Profile
```

Home should be the primary discovery experience.

Services should contain the service catalog.

Bookings should contain:

* Upcoming
* Active
* Completed

Notifications should show real system events.

Profile should contain:

* Personal information
* Saved locations
* Language
* Account
* Logout

---

# 4. WORKER NAVIGATION

Worker navigation should be:

```text id="52p7q8"
Home
Jobs
Earnings
Notifications
Profile
```

Worker Home should clearly communicate:

* Verification status
* Availability
* Today's jobs
* Current active job

Jobs:

```text id="nq1j9a"
Requests
Upcoming
Active
Completed
```

Earnings:

* Real completed-job earnings
* Welfare contribution
* Available/earned amount

Profile:

* Personal details
* Skills
* Certifications
* Verification
* Cooperative
* Availability
* Language

---

# 5. COOPERATIVE ADMIN NAVIGATION

Use a proper admin navigation structure such as:

```text id="3zq6dg"
Dashboard
Verification
Workers
Jobs
Profile
```

Do NOT put every function as a giant list of buttons on the dashboard.

---

# 6. FEDERATION ADMIN

Use:

```text id="pj9v1a"
Overview
Cooperatives
Workforce
Analytics
Profile
```

Keep federation functionality focused on oversight.

---

# 7. CRITICAL BUG — WORKER VERIFICATION FLOW

Currently, after a worker gets verified, the application remains on the verification page.

FIX THIS.

The verification state must become part of the worker's actual application state.

Flow:

```text id="9a6d5k"
Unsubmitted
    ↓
Pending Review
    ↓
Approved
    ↓
Worker Home
```

When the cooperative approves the worker:

* Persist approval in Supabase.
* Update the worker state.
* Refresh/invalidate the relevant state.
* Show the verified status.
* Allow the worker to enter the normal Worker Workspace.
* Do NOT keep them trapped on the verification page.

If rejected:

```text id="s3l1jo"
Rejected
   ↓
Show reason
   ↓
Re-upload
   ↓
Pending Review
```

---

# 8. MUMBAI-FIRST GEO EXPERIENCE

For the current MVP, make the marketplace **Mumbai-region focused**.

Do not pretend to support all of India.

The application should support relevant Mumbai-area locations and nearby service discovery.

Also include **Pune** as an explicitly supported region because the current cooperative architecture includes Pune.

The architecture must remain extensible to other cities/states later.

Do NOT hardcode the architecture around Mumbai permanently.

---

# 9. GPS LOCATION

Implement actual GPS functionality.

Use the current recommended Flutter location/geolocation solution after checking official/current documentation.

Flow:

```text id="u5p0gf"
Customer opens Services
        ↓
Location permission
        ↓
Allow
        ↓
Get current location
        ↓
Show service area / nearby workers
```

Handle:

* Permission denied
* Permission permanently denied
* GPS disabled
* Location unavailable
* Network failure

Do not continuously track users.

Only obtain location when necessary.

---

# 10. MAP EXPERIENCE

Integrate an actual map solution.

The customer should be able to:

* See their service location
* See nearby eligible workers where appropriate
* Select/change service location
* Understand approximate worker proximity

Do not expose sensitive worker home locations.

Prefer approximate location or service-area representation where appropriate.

Do not put fake markers on the map.

Only display real worker/location data.

---

# 11. SERVICE SELECTION MUST FEEL REAL

Current service selection should NOT simply be:

```text
Electrician
[Button]
```

Instead:

```text id="2eqwqy"
What service do you need?

🔌 Electrical
🚰 Plumbing
🪚 Carpentry
❄️ AC Repair
🧹 Cleaning
🎨 Painting
🔧 Appliance Repair
```

Then:

```text id="3ibj0g"
Service
   ↓
Location
   ↓
Nearby verified workers
```

Services must come from the real database/service catalog.

Do not use fake workers.

---

# 12. WORKER DISCOVERY

When a customer selects a service:

Query real Supabase data.

Filter by:

1. Verified worker
2. Required skill
3. Availability
4. Supported region
5. Distance

Then display real workers.

If none exist:

```text id="m1p94j"
No verified workers available nearby.
Try another service or location.
```

Do NOT populate the screen with fake workers.

---

# 13. WORKER PROFILE

Worker profile should feel like a real marketplace profile.

Show only actual data:

* Name
* Verified status
* Skills
* Cooperative
* Experience
* Availability
* Real rating if reviews exist
* Service area

If data is missing, do not invent it.

Example:

```text id="c0m3cr"
Experience
Not provided
```

is better than fake "8 years experience".

---

# 14. BOOKING FLOW

Make booking a proper guided flow rather than a collection of buttons.

Recommended:

```text id="4vxt2r"
Choose Service
      ↓
Choose Location
      ↓
Choose Worker
      ↓
Choose Date
      ↓
Choose Time Slot
      ↓
Review Booking
      ↓
Confirm
```

The confirmation page must show:

* Service
* Worker
* Location
* Date
* Time
* Base price
* Emergency fee if applicable
* Welfare contribution
* Total

No hidden charges.

---

# 15. BOOKING STATUS

This is currently missing and MUST be implemented properly.

Customer and worker must see the same booking lifecycle.

Use:

```text id="g2u3c8"
REQUESTED
    ↓
ACCEPTED
    ↓
SCHEDULED
    ↓
WORKER_ON_THE_WAY
    ↓
ARRIVED
    ↓
OTP_VERIFICATION
    ↓
IN_PROGRESS
    ↓
COMPLETED
    ↓
PAYMENT_PENDING
    ↓
PAID
    ↓
REVIEWED
```

Support appropriate cancellation/rejection states.

Use a typed status representation.

Do NOT implement status changes as arbitrary buttons.

---

# 16. JOB REQUEST EXPERIENCE — WORKER

When a customer creates a booking:

Worker receives a real booking request.

Worker should see:

```text id="q9zj5s"
New Service Request

Electrical Repair

Customer:
[Name]

Location:
[Service Area]

Date:
[Date]

Time:
[Time]

Estimated Earnings:
₹XXX

[Accept]
[Decline]
```

When accepted:

```text id="yqz6re"
Booking Accepted ✓
```

The customer must see the updated status.

Use Supabase Realtime where appropriate.

---

# 17. ACTIVE JOB EXPERIENCE

Do NOT treat:

```text
Start Job
Complete Job
```

as two random buttons.

Create a proper active-job screen.

Example:

```text id="5i4l1n"
ACTIVE JOB

Electrical Repair

Customer
Location

Status
Worker is on the way

[Mark Arrived]
```

Then:

```text id="9ox6sk"
ARRIVED

Ask customer for OTP

Enter OTP
[____]

[Verify & Start Job]
```

Only after successful OTP verification:

```text id="t8f2v1"
JOB IN PROGRESS

Started at 10:42 AM

[Mark Job Complete]
```

---

# 18. OTP JOB START VERIFICATION

Implement a real booking-level OTP flow.

Generate an OTP securely for the booking.

Do not hardcode:

```text 1234
```

Do not expose the OTP in the worker interface.

Customer should see something like:

```text id="e7y7s8"
Your service provider has arrived.

Share this verification code with them:
••••
```

Worker enters the OTP.

Verify it server-side.

Only after successful verification:

```text
booking.status = IN_PROGRESS
```

OTP must expire appropriately.

Prevent unlimited attempts.

---

# 19. JOB COMPLETION

After work is completed:

Worker:

```text id="s3p7qf"
Job completed?
[Confirm Completion]
```

Do not immediately mark payment as successful.

Transition:

```text
IN_PROGRESS
     ↓
COMPLETED
     ↓
PAYMENT_PENDING
```

Customer should now be prompted for payment.

---

# 20. RAZORPAY INTEGRATION

Integrate a real Razorpay payment flow.

Before implementation:

READ THE CURRENT OFFICIAL RAZORPAY DOCUMENTATION.

Do not use outdated Flutter examples.

Architecture:

```text id="y0p9kx"
Flutter
   ↓
Create payment request
   ↓
Secure backend / Edge Function
   ↓
Razorpay Order
   ↓
Flutter Razorpay Checkout
   ↓
Payment
   ↓
Server-side verification
   ↓
Supabase payment record
   ↓
Invoice
```

IMPORTANT:

* Never put Razorpay secret keys in Flutter.
* Never trust client-side success alone.
* Verify payment server-side.
* Handle cancellation.
* Handle failure.
* Prevent duplicate payment records.
* Use idempotent payment handling where appropriate.

---

# 21. PAYMENT SCREEN

After job completion:

Customer should see:

```text id="r2yqgd"
Service Completed ✓

Electrical Repair

Worker:
[Name]

Service Charge      ₹500
Welfare Contribution ₹25
Emergency Fee        ₹0
──────────────────────
Total                ₹525

[Pay ₹525]
```

Then actual Razorpay checkout.

After successful verification:

```text id="t3v7kd"
Payment Successful ✓

Invoice generated
```

---

# 22. INVOICE

Generate a real invoice record from the actual booking/payment.

Customer should be able to view:

* Invoice number
* Service
* Worker
* Date
* Amount
* Welfare contribution
* Total
* Payment status

No fake invoice data.

---

# 23. RATING & REVIEW

After payment:

```text id="y0w8xn"
How was your service?

★★★★★

[Write a review]

[Submit]
```

Only allow the customer to review a completed/paid booking.

Prevent duplicate reviews.

Worker ratings must be calculated from actual reviews.

If no reviews exist:

Do not show:

```text
4.9 (42)
```

---

# 24. CUSTOMER BOOKING TIMELINE

The customer must be able to open a booking and see its lifecycle.

Example:

```text id="y9g8ry"
✓ Booking Requested
       |
✓ Worker Accepted
       |
✓ Worker Arriving
       |
✓ Worker Arrived
       |
✓ OTP Verified
       |
● Job In Progress
       |
○ Payment
       |
○ Review
```

This is critical to making the application feel real.

---

# 25. WORKER JOB TIMELINE

Worker should see the same lifecycle from their perspective.

The application should clearly communicate what action is currently expected.

Avoid showing multiple confusing action buttons simultaneously.

The UI should guide the user through the next valid state.

---

# 26. REALTIME

Use Supabase Realtime where it materially improves the experience.

At minimum consider:

* Booking status changes
* New job requests
* Verification status changes
* Payment status updates

Do not create unnecessary realtime subscriptions.

Clean up subscriptions correctly.

---

# 27. NOTIFICATIONS

Generate notifications from actual events.

Examples:

```text id="yq5u7v"
Worker accepted your booking.
```

```text id="r8s3a2"
Your worker has arrived.
```

```text id="u7y2j4"
Payment successful.
```

```text id="c3q8sp"
Your worker verification has been approved.
```

Do NOT preload notifications.

---

# 28. DATABASE

Extend the existing schema carefully.

Do NOT recreate existing tables.

Ensure the database supports:

* Booking lifecycle
* Status history
* OTP verification
* Worker location
* Service catalog
* Matching
* Payments
* Invoices
* Reviews
* Notifications

Use migrations.

Add proper indexes.

Add RLS policies.

Use database constraints for state integrity.

---

# 29. SECURITY

Particularly protect:

* Booking ownership
* Worker assignment
* OTP verification
* Payment status
* Worker verification status
* Roles
* Documents
* Location data

Never trust Flutter to decide:

```text
payment = paid
booking = completed
worker = verified
role = admin
```

These must be validated securely.

---

# 30. SCALABILITY

Do NOT build this specifically as a Mumbai-only architecture.

The DATA may initially focus on:

```text
Mumbai
Pune
```

but the architecture must support:

```text
City
 ↓
District
 ↓
State
 ↓
Federation
 ↓
Cooperative
```

Future cities should require data/configuration changes, not a code rewrite.

---

# 31. REMOVE OLD UX PATTERNS

Identify and remove:

* Button-only navigation
* Screens with excessive CTA buttons
* Dead-end screens
* Duplicate navigation
* Verification screens that trap users
* Fake dashboard content
* Placeholder statistics
* Demo worker cards
* Fake payment history
* Fake notifications

Replace them with proper flows and empty states.

---

# 32. NO DUMMY DATA — ABSOLUTE

Do NOT create any fake production data.

If the database is empty:

```text
No workers available
No bookings yet
No reviews yet
No notifications
No analytics data
```

This is intentional.

Do not seed fake production data just to make screenshots look populated.

---

# 33. UI/UX PRINCIPLE

Do not focus on adding more screens.

Focus on:

**Context → Action → Feedback → Next Action**

Every major user action should result in visible feedback.

Example:

```text
Accept Job
    ↓
Booking status changes
    ↓
Customer notified
    ↓
Worker sees active job
```

Not:

```text
Accept Job
    ↓
Nothing visibly changes
```

---

# 34. TEST THE COMPLETE JOURNEY

Create/expand tests for:

### Customer

```text
Signup
→ Onboarding
→ Select Service
→ Location
→ Worker
→ Booking
→ Payment
→ Review
```

### Worker

```text
Signup
→ Onboarding
→ Verification
→ Approval
→ Worker Home
→ Job Request
→ Accept
→ Arrive
→ OTP
→ Start
→ Complete
→ Earnings
```

### Cooperative

```text
Login
→ Verification Queue
→ Review Documents
→ Approve
→ Worker becomes verified
```

---

# 35. MANUAL DEMO TEST

Before declaring the feature complete, perform this exact scenario using REAL Supabase records:

```text id="8l7r9p"
1. Create customer
2. Create worker
3. Complete worker onboarding
4. Cooperative verifies worker
5. Worker enters Worker Home
6. Worker becomes available
7. Customer enables GPS
8. Customer selects service
9. Customer sees nearby verified worker
10. Customer books worker
11. Worker receives request
12. Worker accepts
13. Customer sees Accepted
14. Worker marks Arrived
15. Customer receives OTP
16. Worker enters OTP
17. Job becomes In Progress
18. Worker completes job
19. Customer sees Payment Pending
20. Customer pays through Razorpay
21. Payment is verified
22. Invoice appears
23. Customer submits review
24. Worker earnings update
25. Cooperative/federation analytics update
```

If this journey cannot be completed, the application is NOT finished.

---

# 36. DO NOT BREAK EXISTING FUNCTIONALITY

Preserve:

* Supabase Auth
* Existing RBAC
* Existing onboarding foundation
* Worker verification
* RLS
* Existing clean architecture
* Existing tests

Refactor where necessary, but do not casually rewrite working systems.

---

# 37. DOCUMENTATION

Update the architecture documentation to reflect the actual final system.

Document:

* User journeys
* Navigation
* Booking state machine
* Payment lifecycle
* GPS matching
* OTP verification
* RBAC
* Database relationships

Keep documentation concise.

---

# 38. FINAL QUALITY BAR

The application should no longer feel like:

> "Here are a bunch of buttons demonstrating features."

It should feel like:

> **"I can actually use this application to hire a verified local worker from my area."**

The customer should always understand:

**Where am I? → What am I doing? → What happened? → What happens next?**

The worker should always understand:

**Do I have work? → What job is active? → What do I need to do now? → How much did I earn?**

The cooperative should always understand:

**Who needs verification? → Who is working? → What jobs are happening?**

The federation should always understand:

**How is the network performing?**

---

# FINAL RULE

Do not add another isolated feature.

First understand the complete system.

Then restructure the UX and implement the missing real-world flows so that the entire application works as ONE coherent product.

Follow:

```text id="u2v1r0"
INSPECT
↓
UNDERSTAND COMPLETE ARCHITECTURE
↓
READ CURRENT OFFICIAL DOCS
↓
PLAN
↓
DATABASE
↓
NAVIGATION
↓
GPS + MATCHING
↓
BOOKING LIFECYCLE
↓
OTP
↓
PAYMENT
↓
INVOICE
↓
REVIEW
↓
REALTIME
↓
TEST
↓
POLISH
```

**No dummy data. No fake functionality. No disconnected screens.**
