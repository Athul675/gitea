-- ==============================================================================
-- Gitea Storage Quota System - Initial Data Seed & Permissions
-- Description: Dynamically seeds team quota policies based on existing Gitea 
--              teams and grants table privileges to the application user.
-- ==============================================================================

BEGIN;

-- 1. Insert or Update Team Quota Policies Dynamically
-- Allocation Map:
--   Developers -> 5 GiB (5,368,709,120 bytes)
--   Testers    -> 1 GiB (1,073,741,824 bytes)
--   DevOps     -> 1 GiB (1,073,741,824 bytes)
INSERT INTO quota_team (team_id, team_name, quota_per_member_bytes)
SELECT 
    id AS team_id, 
    name AS team_name, 
    CASE LOWER(name)
        WHEN 'developers' THEN 5368709120  -- 5 GiB
        WHEN 'testers'    THEN 1073741824  -- 1 GiB
        WHEN 'devops'     THEN 1073741824  -- 1 GiB
    END AS quota_per_member_bytes
FROM "team"
WHERE LOWER(name) IN ('developers', 'testers', 'devops')
ON CONFLICT (team_id) DO UPDATE 
SET quota_per_member_bytes = EXCLUDED.quota_per_member_bytes,
    updated_at = CURRENT_TIMESTAMP;

-- 2. Grant Table Access to Gitea Application User
GRANT SELECT, INSERT, UPDATE, DELETE 
ON quota_team, quota_user, quota_git_object, quota_reservation 
TO gitea;

-- 3. Grant Sequence Access for Auto-Incrementing IDs
GRANT USAGE, SELECT 
ON SEQUENCE quota_reservation_reservation_id_seq 
TO gitea;

COMMIT;

-- 4. Verification Query (Optional check)
SELECT 
    team_id, 
    team_name, 
    quota_per_member_bytes, 
    enabled 
FROM quota_team 
ORDER BY team_id;
