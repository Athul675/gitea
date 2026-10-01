# Gitea Server & Storage Quota POC

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



## ⚙️ Environment Specifications

### 🖥️ Platform

```text
Operating System : Ubuntu 22.04 LTS / 24.04 LTS
Git Core         : v2.34.1+
Gitea            : v1.22.3
PostgreSQL       : 14+
Nginx            : Current supported version
Fail2ban         : Current supported version


### Component Roles

+----------------------+-----------------------------------------------+
| Component            | Role                                          |
+----------------------+-----------------------------------------------+
| Operating System     | Host operating system                         |
| Git Core             | Git object inspection and repository handling |
| Gitea                | Self-hosted Git management service            |
| PostgreSQL           | Quota and storage accounting database         |
| Nginx                | Reverse proxy and TLS termination             |
| Fail2ban             | Brute-force and intrusion mitigation          |
+----------------------+-----------------------------------------------+

### 📦 Target Repositories

Repository 1 : gitea-demo/web-app.git
Repository 2 : gitea-demo/backend.git
Repository 3 : gitea-demo/payment-service.git



