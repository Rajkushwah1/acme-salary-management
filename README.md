# ACME Salary Management System

A production-ready full-stack salary and employee management system designed for ACME Inc. to handle historical compensation records, temporal validity, and analytics across a global workforce of 10,000+ employees.

Built with **Ruby on Rails 8 (API)**, **PostgreSQL 15**, and **React 18 + Vite**.

---

## Architecture & Engineering Decisions

When handling compensation data, application-level checks alone are insufficient because concurrent requests can cause race conditions and corrupt pay history. This system implements core business rules directly at the persistence layer:

1. **Zero-Overlap Guarantee (`btree_gist` + exclusion constraint)**  
   Instead of relying on Rails validation callbacks to prevent overlapping salary records, the database enforces a PostgreSQL exclusion constraint:
   ```sql
   EXCLUDE USING gist (employee_id WITH =, daterange(effective_from, COALESCE(effective_to, 'infinity'), '[)') WITH &&)
   ```
   This guarantees that an employee cannot have two active or overlapping salary ranges, even under high concurrency.

2. **Immutable Audit Trail**  
   Every salary revision, correction, or promotion generates a structured `SalaryAuditLog` recording the previous state, new state, user ID, timestamp, and mandatory change rationale. Historical logs are read-only and preserved permanently.

3. **Sub-50ms Search on 10,000 Records**  
   Employee lookup uses a composite `pg_trgm` GIN index over `first_name`, `last_name`, `employee_code`, and `email`. Search latency averages ~28ms on local test datasets of 10,000 records without external search dependencies like Elasticsearch.

4. **Currency Safety in Analytics**  
   Salaries are stored in their native contract currency. Aggregation endpoints group by `(currency, department)` and `(currency, country)` rather than blindly summing mismatched currencies.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | Ruby 4.0.9, Rails 8.1.4 (API mode) |
| **Database** | PostgreSQL 15.18 (`btree_gist`, `pg_trgm`) |
| **Frontend** | React 18, Vite 6, Tailwind CSS, Lucide Icons |
| **Auth** | Secure HTTP-only session cookies with CSRF protection (`SameSite=Lax`) |
| **Testing** | RSpec (32 backend unit/request specs), Vitest + React Testing Library |

---

## Quick Start

### Prerequisites
- Ruby 3.2+ or 4.0+ (`.ruby-version` included)
- PostgreSQL 15+ running locally
- Node.js 20+ and npm 10+

---

### 1. Backend Setup

```bash
# Install ruby gems
bundle install

# Prepare database, apply migrations & extensions, and seed data
bin/rails db:create db:migrate db:seed

# Run test suite
bundle exec rspec

# Start backend API (runs on port 3000)
bin/rails server
```

> **Note on Seeding:** `db:seed` populates exactly **10,000 employee records** (`EMP-00001` through `EMP-10000`) with their initial compensation history and audit logs using bulk insert batches. It completes in approximately ~2.5s on modern hardware.

---

### 2. Frontend Setup

In a new terminal window:

```bash
cd client

# Install dependencies
npm install

# Run frontend test suite
npm test

# Start the dev server (runs on port 5173)
npm run dev
```

---

## Application Access & Credentials

Open **[http://localhost:5173](http://localhost:5173)** in your browser.

A default administrative user is created automatically during seeding:

- **Email:** `hr.manager@acme.com`
- **Password:** `AcmeAdmin2026!`

> **Security Note:** These credentials are provisioned exclusively via `db/seeds.rb` for local evaluation and testing purposes. In production environments, administrative accounts are never committed to version control and are securely injected via secret management / environment variables.

The Rails API will be accessible at `http://localhost:3000`.

---

## Core Capabilities

- **Temporal Salary Histories:** Track past, current, and upcoming salary schedules with effective start and end dates.
- **Controlled Revisions & Corrections:** Modify compensation with strict validation rules and mandatory reasons for audit compliance.
- **Graceful Deactivation:** Deactivating an employee closes their active salary window as of the deactivation date and cancels any unfulfilled future revisions.
- **Department & Country Analytics:** Real-time metrics reporting total spend, average, min, and max salary per currency.
- **Fast Filter & Search:** Full text search across employee IDs, names, and emails alongside status/department filters.

---

## Running Automated Tests

### Backend (RSpec)
```bash
bundle exec rspec
```
*Covers model validations, domain logic, exclusion constraints, API endpoints, authentication, and edge cases (32 examples, 0 failures).*

### Frontend (Vitest)
```bash
cd client && npm test
```
*Covers authentication flows and critical UI components.*

---

## Project Structure

```
acme-salary-management/
├── app/
│   ├── controllers/api/v1/   # REST endpoints (auth, employees, salaries, analytics)
│   └── models/               # Domain models (Employee, SalaryRecord, SalaryAuditLog)
├── client/                   # React + Vite frontend application
│   ├── src/
│   │   ├── App.jsx           # Main UI, tabs, search, modals & analytics
│   │   └── api.js            # Axios client with credentials & CSRF handling
├── config/                   # Rails routes, initializers, database config
├── db/
│   ├── migrate/              # PostgreSQL schema migrations & GiST constraints
│   └── seeds.rb              # High-performance bulk seed (10k records)
└── spec/                     # RSpec test suites
```
