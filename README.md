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
