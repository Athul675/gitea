-- ==============================================================================
-- Gitea Storage Quota System - Database Schema
-- Database: PostgreSQL 14+
-- Description: Sets up quota tables, check constraints, and lookup indexes.
-- ==============================================================================

BEGIN;

-- 1. Team Quota Policy Table
CREATE TABLE IF NOT EXISTS quota_team (
    team_id BIGINT PRIMARY KEY,
    team_name VARCHAR(255) NOT NULL,
    quota_per_member_bytes BIGINT NOT NULL CHECK (quota_per_member_bytes > 0),
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. User Active Quota & Accounting Table
CREATE TABLE IF NOT EXISTS quota_user (
    user_id BIGINT PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    team_name VARCHAR(255) NOT NULL,
    quota_bytes BIGINT NOT NULL CHECK (quota_bytes > 0),
    reserved_bytes BIGINT NOT NULL DEFAULT 0 CHECK (reserved_bytes >= 0),
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Git Object Ledger Table
CREATE TABLE IF NOT EXISTS quota_git_object (
    repository_id BIGINT NOT NULL,
    object_oid VARCHAR(64) NOT NULL,
    user_id BIGINT NOT NULL,
    size_bytes BIGINT NOT NULL CHECK (size_bytes >= 0),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (repository_id, object_oid)
);

-- Indexes for Git Object Ledger
CREATE INDEX IF NOT EXISTS idx_quota_git_object_user ON quota_git_object(user_id);
CREATE INDEX IF NOT EXISTS idx_quota_git_object_repo ON quota_git_object(repository_id);

-- 4. Temporary Quota Reservation Table
CREATE TABLE IF NOT EXISTS quota_reservation (
    reservation_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    repository_id BIGINT NOT NULL,
    push_key VARCHAR(128) NOT NULL,
    object_oid VARCHAR(64) NOT NULL,
    size_bytes BIGINT NOT NULL CHECK (size_bytes >= 0),
    status VARCHAR(16) NOT NULL DEFAULT 'reserved' 
        CHECK (status IN ('reserved', 'committed', 'released')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Quota Reservation
CREATE INDEX IF NOT EXISTS idx_quota_reservation_user ON quota_reservation(user_id);
CREATE INDEX IF NOT EXISTS idx_quota_reservation_push ON quota_reservation(push_key);
CREATE INDEX IF NOT EXISTS idx_quota_reservation_status ON quota_reservation(status);
CREATE INDEX IF NOT EXISTS idx_quota_reservation_repo_object ON quota_reservation(repository_id, object_oid);

COMMIT;
