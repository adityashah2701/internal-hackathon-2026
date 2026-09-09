# Database Migrations

This directory holds PostgreSQL schema migrations for PS-089.

## Guidelines
* All schema changes must be versioned through migrations using `npx supabase migration new <name>`.
* RLS (Row Level Security) must be enabled on every table.
* Do not apply migrations manually on the production database.
* Keep migrations incremental and idempotent where possible.
