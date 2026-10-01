# Gitea Server & Storage Quota POC

A complete Gitea deployment and custom per-user cumulative Git storage quota POC using Ubuntu, PostgreSQL, Gitea, Nginx, Fail2ban, Git hooks, and PostgreSQL-based quota accounting.

---

## Overview

This repository contains the full production setup and configuration artifacts for deploying a self-hosted Gitea instance with enterprise-grade custom storage quotas.

### Key Capabilities
- **Gitea Core Setup**: systemd service integration, custom configuration (`app.ini`), and PostgreSQL database backend.
- **Reverse Proxy & Security**: Nginx configuration for proxying Gitea, alongside Fail2ban rules to protect SSH/HTTP login attempts.
- **Cumulative Git Storage Quota**: Custom `pre-receive` and `post-receive` hooks preventing users from exceeding allocated storage across all repositories.
- **Automated Deployment**: Executable shell scripts for central hook deployment and symlinking across Gitea repositories.

---

## Architecture

```text
                    Git Client
                        |
                        v
                      Nginx (Port 80)
                        |
                        v
                 Gitea Web / Git (Port 3001)
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
   Pre/Post Receive Hooks (/usr/local/lib/gitea)




Environment & System DetailsComponentValueOSUbuntu 22.04 LTS / 24.04 LTSGitea Version1.22.3Git Version2.34.1+DatabasePostgreSQL 14+Reverse ProxyNginxSecurityFail2banTargeted Repositoriesgitea-demo/web-app.gitgitea-demo/backend.gitgitea-demo/payment-service.gitQuota PolicyQuota policy is defined by team assignment, but usage and limits are tracked individually per user across all repositories they push to.TeamUsersQuota per UserDevelopersuser1, user2, user35 GiBTestersuser4, user5, user61 GiBDevOpsuser7, user8, user91 GiBCumulative Storage ExampleIf user4 pushes code across multiple repositories:Plaintextuser4
├── web-app.git       (300 MB)
├── backend.git       (400 MB)
└── payment-service.git (200 MB)
       │
       └── Total Cumulative Usage: 900 MB / 1 GiB Quota Limit




Repository StructurePlaintext.
├── README.md
├── configs/
│   ├── app.ini.example          # Sample Gitea configuration file
│   ├── gitea.service            # Systemd service unit definition
│   ├── nginx.conf               # Nginx reverse proxy configuration
│   └── fail2ban/
│       ├── gitea-filter.conf    # Fail2ban filter rules for Gitea log parser
│       └── gitea-jail.local     # Fail2ban jail configuration
├── scripts/
│   ├── install-hooks.sh         # Dynamic installer script for repository symlinks
│   ├── quota-pre-receive        # Central pre-receive validation script
│   └── quota-post-receive       # Central post-receive accounting script
└── sql/
    ├── 01_schema.sql            # Table definitions (quota_user, quota_git_object, quota_reservation)
    └── 02_seed_quotas.sql       # Seed data for user quotas and permissions




Deployment & Setup Guide1. Database SetupApply the quota database tables and seed values to your PostgreSQL database:Bashpsql -U gitea -d giteadb -f sql/01_schema.sql
psql -U gitea -d giteadb -f sql/02_seed_quotas.sql



2. System Service & Reverse ProxyCopy configuration files to their respective system directories:Bash# Systemd

sudo cp configs/gitea.service /etc/systemd/system/gitea.service
sudo systemctl daemon-reload
sudo systemctl enable --now gitea



# Nginx
sudo cp configs/nginx.conf /etc/nginx/sites-available/gitea
sudo ln -sf /etc/nginx/sites-available/gitea /etc/nginx/sites-enabled/
sudo systemctl restart nginx



# Fail2ban
sudo cp configs/fail2ban/gitea-filter.conf /etc/fail2ban/filter.d/gitea.conf
sudo cp configs/fail2ban/gitea-jail.local /etc/fail2ban/jail.d/gitea.local
sudo systemctl restart fail2ban



3. Deploy Git Quota HooksRun the automated installation script to centralize the hook scripts and link them to target repositories:Bashchmod +x scripts/install-hooks.sh
sudo ./scripts/install-hooks.sh

Quota Enforcement WorkflowPlaintextGit Push Request
   │
   ▼
[Pre-Receive Hook]
   ├── 1. Identify User (GITEA_PUSHER_ID / GITEA_PUSHER_NAME)
   ├── 2. Calculate Size of Incoming Git Objects
   ├── 3. Fetch Existing Usage from database:
   │      SELECT SUM(size_bytes) FROM quota_git_object WHERE user_id = $PUSHER_ID
   └── 4. Check Enforcement:
          IF (Used + Reserved + Incoming) <= Quota Limit
              ──► Create Reservation in 'quota_reservation' ──► ACCEPT PUSH
          ELSE
              ──► REJECT PUSH (Exit Code 1)
   │
   ▼
[Post-Receive Hook]
   ├── 1. Read Reservation Key
   ├── 2. Write New Git Objects to 'quota_git_object'
   └── 3. Clear Temporary Reservation from 'quota_reservation'
Limitations & Edge CasesGit LFS: Storage quota currently applies strictly to standard Git objects (blobs, trees, commits). Git LFS objects stored via external pointers are not tracked in this implementation.History Deletions: Deleting files or branches in Git does not automatically reduce quota usage because objects remain stored in repository history until git gc is performed manually.Scope: Enforcement operates at the Git object/database layer, not as a OS filesystem disk quota.Security GuidelinesDo not commit production credentials, passwords, database passwords, or private keys to source control.Use sanitized templates (app.ini.example) for committing configuration baselines.
