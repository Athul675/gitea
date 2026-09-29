Gitea Server & Storage Quota POC

A complete Gitea deployment and custom per-user cumulative Git storage quota POC using Ubuntu, PostgreSQL, Gitea, Nginx, Fail2ban, Git hooks, and PostgreSQL-based quota accounting.

Overview

This project covers:

Gitea installation on Ubuntu
PostgreSQL database configuration
Gitea binary installation
systemd service configuration
Gitea web installation
Organization, users, teams, and repositories
Nginx reverse proxy
Fail2ban configuration
Custom per-user cumulative Git storage quota
Git pre-receive and post-receive quota enforcement
PostgreSQL-based Git object accounting
Quota validation and testing


Architecture

                    
                    Git Client
                        |
                        v
                      Nginx
                        |
                        v
                 Gitea Web / Git
                        |
          +-------------+-------------+
          |                           |
          v                           v
     PostgreSQL                 Git Repositories
          |
          v
     Quota Tables
          |
          v
   Pre/Post Receive Hooks
Environment
Component	Value
OS	Ubuntu
Gitea	1.22.3
Git	2.34.1
Database	PostgreSQL
Reverse Proxy	Nginx
Security	Fail2ban
Gitea Repositories

The POC uses:

gitea-demo/Web-app
gitea-demo/Backend
gitea-demo/Payment-service
Quota Policy
Team	Users	Quota per User
Developers	user1, user2, user3	5 GiB
Testers	user4, user5, user6	1 GiB
DevOps	user7, user8, user9	1 GiB

The quota is assigned according to team membership, but usage is tracked independently for each user.

Quota is cumulative across all configured repositories.

For example:

user4
├── Web-app
├── Backend
└── Payment-service
       |
       +--> All usage counts toward user4's quota
Repository Structure
gitea-server-quota-poc/
│
├── README.md
├── .gitignore
│
├── docs/
│   ├── 01-gitea-server-setup.md
│   └── 02-storage-quota.md
│
├── scripts/
│   ├── quota-pre-receive
│   └── quota-post-receive
│
├── sql/
│   ├── 01-quota-schema.sql
│   ├── 02-quota-users.sql
│   └── 03-quota-grants.sql
│
├── config/
│   ├── systemd/
│   │   └── gitea.service.example
│   ├── nginx/
│   │   └── gitea.conf.example
│   └── fail2ban/
│       ├── gitea.conf
│       └── gitea.local
│
└── tests/
    └── quota-validation.md
Deployment Order

Follow the documentation in this order:

1. Gitea Server Setup

Open Gitea Server Setup

This covers:

Ubuntu Preparation
        ↓
PostgreSQL
        ↓
Gitea Binary
        ↓
systemd
        ↓
Web Installation
        ↓
Initial Gitea Configuration
        ↓
Nginx
        ↓
Fail2ban
2. Storage Quota

Open Storage Quota Documentation

This covers:

Quota Database
      ↓
Quota User Configuration
      ↓
Pre-Receive Hook
      ↓
Post-Receive Hook
      ↓
Repository Hook Installation
      ↓
Quota Validation
Quota Implementation

The quota implementation uses two central scripts:

scripts/quota-pre-receive
scripts/quota-post-receive

These scripts are deployed on the Gitea server as:

/usr/local/lib/gitea/quota-pre-receive
/usr/local/lib/gitea/quota-post-receive

Each repository contains z-quota symlinks pointing to the central scripts.

PostgreSQL Tables

The quota implementation uses:

quota_user
quota_git_object
quota_reservation
quota_user

Stores the user's quota and reservation information.

quota_git_object

Tracks Git objects that have been charged to a user.

quota_reservation

Tracks quota temporarily reserved during an active push.

Quota Enforcement

For each push:

Git Push
   |
   v
Identify User
   |
   v
Calculate New Git Objects
   |
   v
Calculate Incoming Size
   |
   v
Check:

used + reserved + incoming <= quota
   |
   +------ Yes ------> Allow Push
   |
   +------ No -------> Reject Push
Validation

The quota implementation is validated using:

Normal Git push
Quota exceeded rejection
Cumulative usage across repositories
Different users
Same-team user isolation
Reservation and post-receive accounting

See:

Quota Validation

Important Limitations
Git LFS

The current implementation accounts for normal Git objects only.

Git objects → Supported
Git LFS     → Not currently accounted
Existing Repository Data

Git objects that existed before quota deployment are treated as the initial repository baseline.

Deleted Files

Deleting a file does not automatically release quota because Git objects may remain in repository history.

Quota Type

This is a Git object storage quota, not a Linux filesystem quota.

Security

Do not commit:

/var/lib/gitea/.pgpass
/etc/gitea/app.ini
Passwords
Database credentials
API tokens
Private SSH keys
TLS private keys

Use the provided .example configuration files for environment-specific configuration.

Result

The implementation demonstrates:

✓ Team-based quota assignment
✓ Per-user quota
✓ Different quota sizes
✓ Cumulative usage across repositories
✓ Same-team user isolation
✓ Push rejection when quota is exceeded
✓ Quota reservation
✓ Post-receive accounting
✓ Git object-level accounting
Project Purpose

This repository provides a reproducible reference for deploying Gitea and implementing a custom per-user cumulative Git storage quota using Git hooks and PostgreSQL.
