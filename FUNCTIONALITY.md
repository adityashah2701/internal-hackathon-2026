# Sahayog Platform — System Architecture & Feature Reference

**Sahayog** (सहयोग) is India's first **Cooperative-Owned Digital Labour & Service Marketplace**. It replaces exploitative corporate gig aggregator models (which extract 25%–35% commissions from gig workers) with a 0% commission, community-governed cooperative structure where surplus value is returned to workers through a 5% state-backed cooperative welfare pool.

---

## 1. System Architecture Overview

```
                      ┌──────────────────────────────────────┐
                      │        Federation Apex Portal        │
                      │  (State Ministry / Apex Federation)  │
                      └──────────────────┬───────────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
   ┌───────────────────────────┐                   ┌───────────────────────────┐
   │ Primary Cooperative Society│                   │ Primary Cooperative Society│
   │      (e.g., Pune Union)   │                   │   (e.g., Bengaluru Union) │
   └─────────────┬─────────────┘                   └─────────────┬─────────────┘
                 │                                               │
        ┌────────┴────────┐                             ┌────────┴────────┐
        ▼                 ▼                             ▼                 ▼
  ┌───────────┐     ┌───────────┐                 ┌───────────┐     ┌───────────┐
  │  Worker   │     │ Customer  │                 │  Worker   │     │ Customer  │
  └───────────┘     └───────────┘                 └───────────┘     └───────────┘
```

The system is organized into a **Clean Architecture** pattern built in Flutter and Dart, powered by **Supabase** for Auth, Postgres Database, Storage, and Row-Level Security (RLS).

---

## 2. Core Modules & Implemented Features

### A. Authentication & Onboarding
- **Animated Splash Screen**:
  - Branded emblem with elevation, glow, and entrance scale/fade transitions.
  - Automatic session detection that routes to the user's role workspace or the sign-in screen.
  - Institutional badge acknowledging the *Cooperative Federation of India*.
- **Clean Full-Bleed Sign In**:
  - Header-free, vertically centered authentication layout.
  - Email and password sign-in backed by Supabase Auth with real-time validation.
- **Registration**:
  - Streamlined account creation with elevation-free, transparent navigation.
- **4-Step Onboarding Wizard**:
  - **Step 1 (Welcome)**: Introduces the cooperative philosophy (zero corporate commission, welfare pool).
  - **Step 2 (Personal Profile)**: Captures worker/customer legal full name, phone number, and primary district.
  - **Step 3 (Role Commitment)**: Enforces Role-Based Access Control selection (`customer`, `worker`, `cooperative_admin`, `federation_admin`).
  - **Step 4 (Review & Confirmation)**: Locks profile details and sets initial onboarding status.
- **Central GoRouter RBAC Guard**:
  - Route guards prevent cross-portal navigation (e.g., a customer cannot access admin screens).
  - Automatically redirects authenticated users to their specific role dashboard.

---

### B. Customer Marketplace Portal (`/customer`)
- **Direct Cooperative Guarantee**:
  - Highlights verified union professionals with no surge pricing and 0% middleman fees.
- **Service Categories Grid**:
  - Live catalog: Electrician, Plumber, Carpenter, AC Service & Repair, Home Painting, Appliance Repair.
  - Real-time search by trade, skill keyword, or appliance.
- **4-Step Service Booking Sheet**:
  - **Step 1**: Service category confirmation.
  - **Step 2**: Preferred service date selection (Today, Tomorrow, Pick Date) and time slot (Morning, Afternoon, Evening).
  - **Step 3**: Delivery address input and emergency dispatch toggle (+₹100 for 45-minute response).
  - **Step 4**: Transparent cost summary:
    - Base Service Charge
    - Transparent Cooperative Welfare Contribution (5%)
    - Total upfront billing with zero hidden aggregator cuts.
- **Customer Bookings Dashboard**:
  - Live listing of active, scheduled, and past service bookings.
  - Clean empty state (`No service bookings yet`) when the user has no booking history.

---

### C. Worker Workspace & Verification (`/worker`)
- **Worker Verification Lifecycle**:
  - Displays real-time verification status with visual badges:
    - `Unsubmitted`: Prompts worker to begin their cooperative onboarding.
    - `Pending Review`: Notifies worker that their local primary society is reviewing documentation.
    - `Approved / Certified`: Grants the official *Federation Certified* badge.
    - `Rejected`: Transparently displays rejection remarks with the ability to re-upload.
- **Real-Time Availability Toggle**:
  - Instant on-duty / off-duty switch synchronized with local state and backend.
- **Trade Skills & Primary Society Affiliation**:
  - Displays certified trades and primary cooperative society affiliation.
  - Interactive modal to edit trade skills and society affiliation.
- **KYC & Trade Certification Upload Vault**:
  - Supports uploading document types:
    - Aadhaar Card (Govt ID)
    - ITI / NSDC Trade Certificate
    - Cooperative Membership Card
    - Police Verification Clearance
    - Voter Identity Card
    - PAN Card
  - Directly uploads files to the Supabase encrypted Storage bucket (`kyc-documents`).
  - Generates SHA-256 digital checksums for audit validation.

---

### D. Cooperative Operations Portal (`/cooperative`)
- **Cooperative Telemetry Overview**:
  - Live metric tiles displaying Active Workers, Jobs Done, and Society Welfare Pool (INR).
  - Accurately starts at zero or calculates from real completed bookings without fake minimums.
- **Verification Review Queue**:
  - Filter tabs: `Pending`, `Approved`, `Rejected`, and `All Roster`.
  - Applicant cards showing worker name, contact, trade experience, and affiliation.
- **Document Inspector Bottom Sheet**:
  - Allows society officers to inspect uploaded documents, check digital hash checksums, review MIME types, and download original files from Supabase Storage.
- **One-Tap Approval & Rejection Flow**:
  - Approve worker: Updates database record, stamps `verified_by` and `verified_at`, and grants certification.
  - Reject worker: Requires a specific, mandatory feedback reason logged to the database for worker re-submission.

---

### E. Federation Apex Oversight (`/federation`)
- **State Telemetry KPIs**:
  - High-level executive dashboard showing:
    - Total registered workforce.
    - Verified & certified workers.
    - Pending queue volume across all primary societies.
    - Number of active primary societies registered in the state.
- **Affiliated Primary Societies Roster**:
  - Horizontal card carousel displaying society name, code, district, and state.
  - Integrated empty state when no societies are registered.
- **State Workforce Registry**:
  - Searchable by worker name, skill trade, or locality.
  - Status filter chips (`All`, `Verified Only`, `Pending Approval`, `Rejected`).

---

### F. Backend Database & Security (Supabase / Postgres)
- **Migrations**:
  - `20260909000001_create_profiles_and_rbac.sql`: Custom `user_role` enum, `profiles` table, strict RLS policies, trigger-enforced immutable roles (`check_profile_role_update`).
  - `20260909000002_worker_verification_and_cooperatives.sql`: `cooperatives` table, `worker_profiles` table, `worker_documents` table, storage bucket setup with folder-isolated RLS.
  - `20260909000003_bookings_and_welfare.sql`: `bookings` table, welfare pool calculations, booking status progression.
- **Storage**:
  - Dedicated `kyc-documents` bucket with signed URL generation (1-hour expiry).

---

## 3. Product Integrity & Design Principles

1. **Empty is Better than Fake**:
   - Fabricated analytics, mock review scores (`4.9 (42)`), and dummy personas have been removed.
   - Dashboards reflect real Supabase data and show clean, intentional empty states when the database is empty.
2. **Header-Free Immersive UX**:
   - Authentication and wizard screens omit redundant AppBar titles for a clean, modern aesthetic.
3. **Strict RBAC**:
   - Roles cannot be self-elevated via client APIs; elevated access (cooperative or federation admin) requires authorized database privileges.

---

## 4. Test & Verification Coverage

The codebase includes **48 automated unit and widget tests** covering:
- Auth controllers and session lifecycle transitions.
- Multi-step onboarding validation and state machine.
- Booking repository, welfare pool calculations, and tracking code generation.
- Federation admin telemetry aggregation and filtering.
- Worker document uploads and verification workflows.
- Splash screen rendering, animations, and navigation timers.

```bash
flutter analyze   # 0 errors, 0 warnings
flutter test      # 48/48 tests passed
```
