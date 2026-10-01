#   Gitea Server & Storage Quota POC

[![Gitea](https://img.shields.io/badge/Gitea-1.22.3-34495E?style=for-the-badge&logo=gitea&logoColor=white)](https://gitea.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Nginx](https://img.shields.io/badge/Nginx-Reverse_Proxy-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://nginx.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_/_24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

> **An enterprise-grade reference architecture for self-hosted Gitea deployments, featuring dynamic, PostgreSQL-backed cumulative Git storage quota enforcement at the server-hook layer.**

---

## 📌 Executive Overview

Standard Git hosting solutions often lack granular, per-user cumulative storage tracking across multiple repositories.

This Proof of Concept (POC) delivers an end-to-end infrastructure setup combining:

- **Gitea**
- **PostgreSQL**
- **Nginx**
- **Fail2ban**
- **Git server-side hooks**
- **PostgreSQL-backed quota tracking**

The solution uses dynamic `pre-receive` and `post-receive` Git hooks to enforce cumulative storage quotas across multiple repositories.

### Key Features

- ⚡ **Centralized Hook Architecture**  
  Executes server-side quota checks through lightweight repository-level symlinks using `z-quota`.

- 📊 **Cumulative Storage Tracking**  
  Evaluates aggregate Git object storage consumption across all repositories for each user.

- 🔒 **Atomic Reservations**  
  Prevents race conditions during simultaneous pushes by using transient quota reservation records.

- 🛡️ **Hardened Proxy & Security**  
  Integrates Nginx as a reverse proxy and Fail2ban for threat mitigation.

- 🤖 **Automated Deployment**  
  Provides an installation script for provisioning quota hooks across target bare Git repositories.

---

# 📐 Architecture & System Flow

```text
                         +------------------+
                         |    Git Client    |
                         +--------+---------+
                                  |
                             HTTP / SSH
                                  |
                                  v
                         +--------+---------+
                         |      Nginx       |
                         |  Reverse Proxy   |
                         +--------+---------+
                                  |
                              Port 3001
                                  |
                                  v
                         +--------+---------+
                         |      Gitea       |
                         |     v1.22.3      |
                         +--------+---------+
                                  |
                 +----------------+----------------+
                 |                                 |
                 v                                 v
        +--------+---------+              +--------+---------+
        |    PostgreSQL    |              |   Repositories   |
        +--------+---------+              +--------+---------+
                 |                                 |
                 v                                 v
        +--------+---------+              +--------+---------+
        |   Quota Tables   |<----Hooks----|    Git Hooks     |
        +------------------+              +------------------+
                 |
                 v
        +------------------+
        | Quota Accounting |
        | & Reservations   |
        +------------------+
```

---

## ⚙️ Environment Specifications

### 🖥️ Platform

```text
Operating System : Ubuntu 22.04 LTS / 24.04 LTS
Git Core         : v2.34.1+
Gitea            : v1.22.3
PostgreSQL       : 14+
Nginx            : Current supported version
Fail2ban         : Current supported version
```

### Component Roles

```text
+----------------------+-----------------------------------------------+
| Component            | Role                                          |
+----------------------+-----------------------------------------------+
| Operating System     | Host operating system                         |
| Git Core             | Git object inspection and repository handling |
| Gitea                | Self-hosted Git management service            |
| PostgreSQL           | Quota and storage accounting database         |
| Nginx                | Reverse proxy and TLS termination             |
| Fail2ban             | Brute-force and intrusion mitigation         |
+----------------------+-----------------------------------------------+
```

### 📦 Target Repositories

```text
Repository 1 : gitea-demo/web-app.git
Repository 2 : gitea-demo/backend.git
Repository 3 : gitea-demo/payment-service.git
```

---

# 📊 Quota Allocation Model

Quotas are configured based on team roles, while storage usage is calculated independently per user across all repositories.

```text
+-------------+--------------------------+------------------+
| Team        | Members                  | Quota Per User   |
+-------------+--------------------------+------------------+
| Developers  | user1, user2, user3      | 5 GiB            |
| Testers     | user4, user5, user6      | 1 GiB            |
| DevOps      | user7, user8, user9      | 1 GiB            |
+-------------+--------------------------+------------------+
```

### Quota Units

```text
1 GiB = 1,073,741,824 bytes

5 GiB = 5,368,709,120 bytes
```

---

# 📈 Cumulative Storage Model

Storage usage is calculated cumulatively across all repositories owned by a user.

For example:

```text
user4
Quota = 1 GiB

    web-app.git
        |
        +---- 300 MB

    backend.git
        |
        +---- 400 MB

    payment-service.git
        |
        +---- 200 MB

-----------------------------
Total Usage = 900 MB
Quota       = 1024 MB

Result      = PUSH ALLOWED
-----------------------------
```

The quota calculation is:

```text
Existing Usage
      +
Active Reservations
      +
Incoming Git Objects
      <=
User Quota
```

---

# 📂 Repository Layout

```text
.
├── README.md
│
├── .gitignore
│
├── configs/
│   ├── app.ini.example
│   ├── gitea.service
│   ├── nginx.conf
│   └── fail2ban/
│       ├── gitea-filter.conf
│       └── gitea-jail.local
│
├── scripts/
│   ├── install-hooks.sh
│   ├── quota-pre-receive
│   └── quota-post-receive
│
└── sql/
    ├── 01_schema.sql
    └── 02_seed_quotas.sql
```

---

# 🚀 Quickstart & Setup Guide

## 1️⃣ Database Initialization

Apply the database schema:

```bash
psql -U gitea -d giteadb -f sql/01_schema.sql
```

Apply the initial quota configuration:

```bash
psql -U gitea -d giteadb -f sql/02_seed_quotas.sql
```

Database details:

```text
Database : giteadb
User     : gitea
Engine   : PostgreSQL
```

---

## 2️⃣ Gitea Service Provisioning

Copy the systemd service file:

```bash
sudo cp configs/gitea.service /etc/systemd/system/gitea.service
```

Reload systemd:

```bash
sudo systemctl daemon-reload
```

Enable and start Gitea:

```bash
sudo systemctl enable --now gitea
```

Verify:

```bash
sudo systemctl status gitea
```

---

## 3️⃣ Nginx Reverse Proxy

Copy the Nginx configuration:

```bash
sudo cp configs/nginx.conf /etc/nginx/sites-available/gitea
```

Create the symbolic link:

```bash
sudo ln -sf /etc/nginx/sites-available/gitea /etc/nginx/sites-enabled/
```

Test the configuration:

```bash
sudo nginx -t
```

Restart Nginx:

```bash
sudo systemctl restart nginx
```

Verify:

```bash
sudo systemctl status nginx
```

---

## 4️⃣ Fail2ban Configuration

Copy the Gitea filter:

```bash
sudo cp configs/fail2ban/gitea-filter.conf \
    /etc/fail2ban/filter.d/gitea.conf
```

Copy the Gitea jail:

```bash
sudo cp configs/fail2ban/gitea-jail.local \
    /etc/fail2ban/jail.d/gitea.local
```

Restart Fail2ban:

```bash
sudo systemctl restart fail2ban
```

Verify:

```bash
sudo systemctl status fail2ban
```

Check the jail:

```bash
sudo fail2ban-client status
```

---

# 🔗 Hook Deployment

The quota enforcement mechanism uses centralized server-side Git hooks.

Central hook location:

```text
/usr/local/lib/gitea/
├── quota-pre-receive
└── quota-post-receive
```

Make the installation script executable:

```bash
chmod +x scripts/install-hooks.sh
```

Run the installation script:

```bash
sudo ./scripts/install-hooks.sh
```

The installer creates the required repository hook directories and symbolic links.

---

# 🔄 Quota Enforcement Lifecycle

```text
                         Git Push
                            |
                            v
                  +-------------------+
                  |  PRE-RECEIVE HOOK |
                  +---------+---------+
                            |
                            v
                  Identify Push User
                            |
                            v
                  Identify Repository
                            |
                            v
                  Discover New Objects
                            |
                            v
                  Calculate Object Size
                            |
                            v
                  Query Existing Usage
                            |
                            v
                  Query Reservations
                            |
                            v
              Used + Reserved + Incoming
                            |
                            v
                    Compare With Quota
                            |
                 +----------+----------+
                 |                     |
                 v                     v
           Quota Exceeded        Quota Available
                 |                     |
                 v                     v
          Reject Push             Reserve Space
                                       |
                                       v
                              +-------------------+
                              |  POST-RECEIVE     |
                              |      HOOK         |
                              +---------+---------+
                                        |
                                        v
                               Record Git Objects
                                        |
                                        v
                               Commit Reservation
                                        |
                                        v
                                  Push Complete
```

---

# 🧮 Pre-Receive Hook

The `quota-pre-receive` hook performs quota validation before the push is accepted.

### Responsibilities

- Identify the authenticated Gitea user.
- Identify the repository.
- Discover newly introduced Git objects.
- Calculate incoming object size.
- Query existing user usage.
- Query active reservations.
- Compare total usage against the user's quota.
- Reject the push if the quota would be exceeded.
- Create a reservation if sufficient quota is available.

Git commands used include:

```bash
git rev-list --objects --stdin --not --all
```

and:

```bash
git cat-file --batch-check
```

---

# 🧾 Post-Receive Hook

The `quota-post-receive` hook finalizes the quota accounting after the push succeeds.

### Responsibilities

- Identify the corresponding reservation.
- Process accepted Git objects.
- Insert objects into `quota_git_object`.
- Mark the reservation as committed.
- Release temporary reserved quota.

---

# 🗄️ PostgreSQL Quota Data Model

The POC uses three primary tables.

## `quota_user`

Stores user-level quota configuration.

```text
quota_user
├── user_id
├── username
├── team_name
├── quota_bytes
├── reserved_bytes
├── enabled
├── created_at
└── updated_at
```

---

## `quota_git_object`

Stores Git objects attributed to users.

```text
quota_git_object
├── repository_id
├── object_oid
├── user_id
└── size_bytes
```

Indexes:

```text
idx_quota_git_object_user
idx_quota_git_object_repo
```

---

## `quota_reservation`

Stores temporary quota reservations during active pushes.

```text
quota_reservation
├── reservation_id
├── user_id
├── repository_id
├── push_key
├── object_oid
├── size_bytes
├── status
├── created_at
└── updated_at
```

Reservation states:

```text
reserved
committed
released
```

Indexes:

```text
idx_quota_reservation_user
idx_quota_reservation_push
idx_quota_reservation_status
idx_quota_reservation_repo_object
```

---

# 🔒 Atomic Reservation Model

Reservations prevent race conditions when multiple pushes occur simultaneously.

Example:

```text
User Quota = 1 GiB
Existing Usage = 700 MB

Push A = 200 MB
Push B = 200 MB
```

Push A:

```text
700 MB + 200 MB = 900 MB

Reservation Created
```

Push B:

```text
700 MB
+ 200 MB Push A
+ 200 MB Push B
----------------
= 1100 MB
```

Result:

```text
❌ Push B Rejected
```

---

# 🔎 Quota Verification

## View User Quotas

```sql
SELECT
    user_id,
    username,
    team_name,
    quota_bytes,
    reserved_bytes,
    enabled
FROM quota_user
ORDER BY user_id;
```

---

## Calculate Usage Per User

```sql
SELECT
    user_id,
    COALESCE(SUM(size_bytes), 0) AS used_bytes
FROM quota_git_object
GROUP BY user_id
ORDER BY user_id;
```

---

## View Active Reservations

```sql
SELECT
    reservation_id,
    user_id,
    repository_id,
    push_key,
    object_oid,
    size_bytes,
    status,
    created_at,
    updated_at
FROM quota_reservation
WHERE status = 'reserved'
ORDER BY created_at;
```

---

# 🧪 Quota Testing

Temporarily reduce a user's quota:

```sql
UPDATE quota_user
SET quota_bytes = 400
WHERE username = 'user4';
```

Verify the quota:

```sql
SELECT
    user_id,
    username,
    team_name,
    quota_bytes,
    reserved_bytes,
    enabled
FROM quota_user
WHERE username = 'user4';
```

Create a test file:

```bash
dd if=/dev/zero of=test-file.bin bs=1K count=1
```

Add and commit:

```bash
git add test-file.bin
git commit -m "Test quota enforcement"
```

Attempt to push:

```bash
git push origin main
```

Expected result when quota is exceeded:

```text
remote: Quota exceeded
remote: Push rejected
```

---

# 📦 Git LFS Scope

> [!NOTE]
> Quota enforcement currently monitors native Git objects such as blobs, trees, and commits.
>
> Git LFS objects are managed separately and are outside the native Git object accounting implemented by this POC.

Check LFS objects:

```sql
SELECT COUNT(*) AS total_lfs_objects
FROM lfs_meta_object;
```

Check total LFS storage:

```sql
SELECT
    COALESCE(SUM(size), 0) AS total_lfs_bytes
FROM lfs_meta_object;
```

---

# ⚠️ History Retention

> [!WARNING]
> Removing a tracked file using `git rm` does not immediately reclaim quota capacity.
>
> Git objects may remain in repository history until they become unreachable and are eventually removed through Git garbage collection.

Example:

```bash
git rm large-file.iso
git commit -m "Remove large file"
git push
```

The previous Git object may still exist in repository history.

Git garbage collection can be performed using:

```bash
git gc
```

---

# 🔐 Security Baseline

## Zero Hardcoded Secrets

Never commit production credentials into the repository.

Sensitive files should remain outside Git tracking:

```text
app.ini
.pgpass
.env
TLS private keys
SSH private keys
API tokens
Database passwords
```

Use sanitized example files:

```text
app.ini.example
```

---

## Recommended `.gitignore`

```gitignore
# Gitea configuration
app.ini

# PostgreSQL credentials
.pgpass

# Environment files
.env
.env.*

# TLS private keys
*.key
*.pem

# SSH private keys
id_rsa
id_ed25519

# Logs
*.log

# Temporary files
*.tmp
*.swp

# Operating system files
.DS_Store
Thumbs.db
```

---

# 🛡️ Nginx Reverse Proxy

The request flow is:

```text
Git Client
    |
    | HTTP / HTTPS
    v
+----------------+
|     Nginx      |
| Reverse Proxy  |
+-------+--------+
        |
        | Port 3001
        v
+----------------+
|     Gitea      |
+----------------+
```

Nginx provides:

- Reverse proxy functionality
- HTTP/HTTPS termination
- TLS integration
- Centralized access logging
- Controlled access to the Gitea service

---

# 🚨 Fail2ban Integration

Fail2ban monitors authentication-related logs and can temporarily ban clients that exceed configured failure thresholds.

```text
Authentication Attempt
          |
          v
      Gitea Logs
          |
          v
       Fail2ban
          |
      +---+---+
      |       |
      v       v
   Normal   Repeated
   Access   Failure
              |
              v
             Ban
```

Configuration files:

```text
configs/fail2ban/gitea-filter.conf
configs/fail2ban/gitea-jail.local
```

---

# 🧹 Repository Storage Checks

Check repository disk usage:

```bash
du -sh /var/lib/gitea/data/gitea-repositories/*
```

Check a specific repository:

```bash
du -sh /var/lib/gitea/data/gitea-repositories/gitea-demo/web-app.git
```

Check Git object statistics:

```bash
git count-objects -v
```

---

# 🧪 POC Validation Scenarios

## Scenario 1: Push Within Quota

```text
Quota       = 1 GiB
Existing    = 500 MB
Incoming    = 200 MB
Reserved    = 0 MB

Total       = 700 MB
```

Expected:

```text
✅ Push Allowed
```

---

## Scenario 2: Push Exceeds Quota

```text
Quota       = 1 GiB
Existing    = 900 MB
Incoming    = 200 MB
Reserved    = 0 MB

Total       = 1100 MB
```

Expected:

```text
❌ Push Rejected
```

---

## Scenario 3: Concurrent Pushes

```text
Quota       = 1 GiB
Existing    = 700 MB

Push A      = 200 MB
Push B      = 200 MB
```

With reservations:

```text
Push A
700 + 200 = 900 MB
Reservation created

Push B
700 + 200 + 200 = 1100 MB

❌ Push B rejected
```

---

# 📋 Operational Checklist

```text
[ ] Ubuntu server installed
[ ] Git installed
[ ] Gitea 1.22.3 installed
[ ] PostgreSQL configured
[ ] giteadb database created
[ ] Gitea database user configured
[ ] Nginx configured
[ ] Fail2ban configured
[ ] Gitea service enabled
[ ] PostgreSQL schema applied
[ ] Quota seed data applied
[ ] Central quota hooks installed
[ ] Repository hook directories created
[ ] Hook symlinks created
[ ] Hook permissions verified
[ ] PostgreSQL connectivity verified
[ ] Git push tested
[ ] Quota rejection tested
[ ] Quota acceptance tested
[ ] Cumulative usage verified
[ ] Reservation behavior verified
[ ] LFS state verified
[ ] No credentials committed
```

---

# ⚠️ Known Limitations

1. Git LFS storage is not included in native Git object accounting.

2. Quota reclamation is not immediate when historical Git objects remain reachable.

3. Garbage collection behavior depends on Git repository reachability and maintenance policies.

4. The quota mechanism is implemented through custom PostgreSQL tables and server-side Git hooks.

5. Custom database tables and hooks must be maintained alongside Gitea upgrades.

6. Hook compatibility should be revalidated after major Gitea or Git upgrades.

7. The POC should be tested thoroughly before being considered for production use.

---

# 🔄 Upgrade Considerations

Before upgrading Gitea or Git:

```text
1. Backup PostgreSQL
        |
        v
2. Backup Gitea configuration
        |
        v
3. Backup quota tables
        |
        v
4. Backup hook scripts
        |
        v
5. Review Gitea hook behavior
        |
        v
6. Upgrade in a test environment
        |
        v
7. Validate Git push
        |
        v
8. Validate quota enforcement
        |
        v
9. Validate PostgreSQL accounting
        |
        v
10. Perform production upgrade
```

PostgreSQL backup:

```bash
pg_dump -U gitea -d giteadb > giteadb-backup.sql
```

---

# 🏗️ Overall Architecture Summary

```text
                         +------------------+
                         |    Git Client    |
                         +--------+---------+
                                  |
                             HTTP / SSH
                                  |
                                  v
                         +--------+---------+
                         |      Nginx       |
                         |  Reverse Proxy   |
                         +--------+---------+
                                  |
                                  v
                         +--------+---------+
                         |      Gitea       |
                         |     v1.22.3      |
                         +--------+---------+
                                  |
                 +----------------+----------------+
                 |                                 |
                 v                                 v
        +--------+---------+              +--------+---------+
        |    PostgreSQL    |              |   Repositories   |
        |                  |              |                  |
        | quota_user       |              | web-app.git      |
        | quota_git_object |              | backend.git      |
        | quota_reservation|              | payment-service  |
        +--------+---------+              +--------+---------+
                 |                                 |
                 |                                 |
                 |                         +-------+-------+
                 |                         |               |
                 |                         v               v
                 |                  Pre-Receive      Post-Receive
                 |                      Hook              Hook
                 |                         |               |
                 |                         +-------+-------+
                 |                                 |
                 +---------------------------------+
                              |
                              v
                     Quota Enforcement
```

---

# 🎯 POC Objective

The objective of this Proof of Concept is to demonstrate cumulative, per-user Git storage quota enforcement across multiple repositories in a self-hosted Gitea environment.

The solution combines:

```text
Gitea
  +
PostgreSQL
  +
Git Server-Side Hooks
  +
Nginx
  +
Fail2ban
  +
Quota Reservations
  =
Cumulative Per-User Storage Enforcement
```

The quota model is user-centric:

```text
                    User
                     |
          +----------+----------+
          |          |          |
          v          v          v
       Repo A     Repo B     Repo C
          |          |          |
          +----------+----------+
                     |
                     v
            Cumulative Usage
                     |
                     v
             PostgreSQL Ledger
                     |
                     v
              Quota Validation
                /         \
               /           \
              v             v
          Allowed         Rejected
```

---

# 📌 Final Notes

This repository is intended as a **Proof of Concept and reference implementation** for cumulative Git storage quota enforcement in a self-hosted Gitea environment.

Before production deployment, validate:

- Gitea upgrade compatibility
- Git version compatibility
- Hook execution behavior
- PostgreSQL transaction behavior
- Concurrent push handling
- Repository garbage collection
- Git LFS requirements
- Backup and recovery procedures
- Security and credential management
- Monitoring and alerting

> **Important:** This POC extends Gitea through custom PostgreSQL tables and server-side Git hooks. It should therefore be treated as an independently maintained extension layer and regression-tested whenever Gitea, Git, PostgreSQL, or the underlying operating system is upgraded.

---

# 📄 License

This project is provided under the MIT License.

See [`LICENSE`](LICENSE) for the complete license text.

---

# 👤 Project Status

```text
Project Type : Proof of Concept
Platform     : Self-Hosted Gitea
Gitea        : 1.22.3
Database     : PostgreSQL 14+
OS           : Ubuntu 22.04 / 24.04 LTS
Proxy        : Nginx
Security     : Fail2ban
Quota Model  : Per-user cumulative storage
Enforcement  : Git server-side hooks
Accounting   : PostgreSQL
Status       : POC
```

---

# 🚀 End of Documentation

```text
Gitea
  |
  +-- Git Hosting
  |
  +-- PostgreSQL
  |      |
  |      +-- User Quotas
  |      +-- Object Ledger
  |      +-- Reservations
  |
  +-- Server-Side Hooks
  |      |
  |      +-- Pre-Receive
  |      +-- Post-Receive
  |
  +-- Nginx
  |      |
  |      +-- Reverse Proxy
  |
  +-- Fail2ban
         |
         +-- Security Layer

              |
              v

       Cumulative Per-User
         Storage Quota
            Enforcement
```
