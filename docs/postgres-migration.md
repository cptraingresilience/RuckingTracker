# PostgreSQL Migration Plan

A step-by-step plan for migrating the `rux-backend` data layer from JSON files to PostgreSQL — **for when you're ready**.

## Guiding principle

This is **not** an app rewrite. Every route file (`auth.js`, `activities.js`, `teams.js`, `leaderboard.js`) only speaks the three verbs exported by `src/data/store.js`:

- `readCollection`
- `writeCollection`
- `updateCollection`

The migration rewrites the **insides of that one file** and moves existing data across. In Stage 1, no route files change.

The plan has two stages:

- **Stage 1 (Phases 1–7):** the safe drop-in swap. App behaves identically, just on PostgreSQL.
- **Stage 2 (Phase 8):** optional performance upgrades, done gradually afterward.

---

## Phase 0 — Prerequisites & decisions

- [ ] **Pick a database host.** Managed options are easiest to start: Railway, Render, Supabase, or Neon (no server admin required).
- [ ] **Decide table shape:**
  - **JSONB approach (recommended for Stage 1):** each table has an `id` column + a single `data` JSONB column holding the whole object. Mirrors current file objects almost exactly → low-risk cutover.
  - **Fully-columned approach:** every field becomes its own column. Cleaner long-term and needed for fastest queries, but more up-front work.
- [ ] Decision: use **JSONB for Stage 1**, migrate hot tables to real columns in Stage 2.

---

## Phase 1 — Stand up a database (no app changes yet)

- [ ] Create the PostgreSQL instance on your chosen host.
- [ ] Copy its connection string: `postgresql://user:password@host:5432/dbname`.
- [ ] Add it to `.env` as `DATABASE_URL` (`.env` is already gitignored).
- [ ] Test the connection in isolation (DB client or a throwaway `pg` script) **before** wiring it into the app.

**Why:** Prove connectivity separately from app bugs.

---

## Phase 2 — Create the tables (schema)

- [ ] Write `rux-backend/src/data/schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS users (
    id   TEXT PRIMARY KEY,
    data JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS activities (
    id   TEXT PRIMARY KEY,
    data JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS teams (
    id   TEXT PRIMARY KEY,
    data JSONB NOT NULL
);
```

- [ ] Run it once against the database.

**Why:** `id` as PRIMARY KEY enforces uniqueness the database now guarantees (no more manual duplicate checks). JSONB stores existing objects intact.

---

## Phase 3 — Write the new `store.js`

- [ ] Rename the current file to `store.file.js` as a safety net (**do not delete yet**).
- [ ] Create the new `store.js` using the `pg` Pool, exporting the **identical** `readCollection` / `writeCollection` / `updateCollection` interface.
- [ ] Keep `writeCollection` transactional (`BEGIN` / `COMMIT` / `ROLLBACK`).
- [ ] Remove the `withCollectionLock` mechanism — PostgreSQL handles concurrent writes.
- [ ] Wire in `logger.js` so DB errors are logged, not silent.

**Why:** This is the only file where the "how" changes. The unchanged contract means the rest of the app doesn't notice.

---

## Phase 4 — Seed the default teams

The old `store.js` auto-created: ODA 555, TX Special Forces Mentorship, Drinking Crew, Go Ruck Friends.

- [ ] Reproduce them via schema or a `seed.js` script:

```sql
INSERT INTO teams (id, data) VALUES
  ('team-oda-555', '{"id":"team-oda-555","name":"ODA 555","members":[]}'),
  ('team-tx-sfm', '{"id":"team-tx-sfm","name":"TX Special Forces Mentorship","members":[]}'),
  ('team-drinking-crew', '{"id":"team-drinking-crew","name":"Drinking Crew","members":[]}'),
  ('team-go-ruck-friends', '{"id":"team-go-ruck-friends","name":"Go Ruck Friends","members":[]}')
ON CONFLICT (id) DO NOTHING;
```

**Why:** `ON CONFLICT DO NOTHING` makes this safe to re-run — no duplicates.

---

## Phase 5 — Migrate existing data (one-time)

- [ ] Write a one-off `migrate.js` that:
  - Reads each JSON file (`users.json`, `activities.json`, `teams.json`) via the old `store.file.js`.
  - Inserts every item into the matching table (`INSERT ... ON CONFLICT (id) DO NOTHING`).
  - Logs counts read vs. inserted.
- [ ] Run against a throwaway/test database first and eyeball results.
- [ ] Verify row counts match file item counts.

**Why:** The one part that isn't automatic — existing data must be copied once. `ON CONFLICT DO NOTHING` makes it safely re-runnable.

---

## Phase 6 — Test everything against the database

Point the local app at the database (new `store.js`) and exercise every route:

- [ ] Sign up, sign in, refresh token
- [ ] Create / list / view / update / delete an activity
- [ ] Summary stats
- [ ] List teams, create a team, join a team
- [ ] Leaderboard (weekly, monthly, all; with and without team filter)
- [ ] Edge cases: duplicate signup (409), missing activity (404), bad token (403)
- [ ] Confirm identical inputs produce identical outputs vs. the file version.

**Why:** Matching behavior here proves the swap is clean. This is the safety gate before production.

---

## Phase 7 — Deploy the cutover

- [ ] Set `DATABASE_URL` in production (never commit it).
- [ ] Run schema + seed against production DB.
- [ ] Run one-time `migrate.js` against production data.
- [ ] Deploy code with the new `store.js`.
- [ ] Smoke-test `/health` and a few live actions.
- [ ] Keep `store.file.js` and JSON files for ~2 weeks as rollback, then remove.

**Why:** Staged cutover with a retained fallback allows quick revert.

---

## Phase 8 — Stage 2: performance upgrades (later, optional, incremental)

- [ ] **Leaderboard first:** replace "load everything and loop" with a single SQL query (filter by date, group by user, sum distance, sort, limit).
- [ ] **Add indexes** on frequently filtered/sorted fields: activity `startedAt`, `userId`, user `email`.
- [ ] **Optionally migrate hot tables to real columns** (activities especially).
- [ ] **Add targeted query functions** to `store.js` (e.g. `getActivitiesForUser(userId)`) so routes stop pulling whole tables into memory.

**Why:** Not required for correctness — the app already works after Phase 7. These are surgical, gradual improvements as the user base grows.

---

## Quick reference: what changes vs. what doesn't

| Changes | Stays the same |
|---|---|
| Inside of `store.js` | `auth.js`, `activities.js`, `teams.js`, `leaderboard.js` (Stage 1) |
| New: schema, seed, migrate scripts | The three verbs `readCollection` / `updateCollection` / `writeCollection` |
| `DATABASE_URL` added to env | Swift app and API endpoints |
| `withCollectionLock` removed | JWT auth, validation, rate limiting, CORS |

---

## A subtle bug this migration fixes

The current file-based `updateCollection` does read-modify-write across separate steps, protected only by an in-memory lock (`withCollectionLock`). That lock lives inside **one running process** — if two copies of the backend ever ran, they could clobber each other's writes. PostgreSQL with primary keys and transactions makes that class of problem the database's responsibility, which it's purpose-built to handle.
