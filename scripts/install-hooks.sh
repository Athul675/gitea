#!/usr/bin/env bash
# ==============================================================================
# Gitea Storage Quota System - Git Hook Installer
# Description: Copies central hook scripts and symlinks them as 'z-quota' into
#              target Gitea bare repositories.
# ==============================================================================

set -euo pipefail

# Configuration
CENTRAL_DIR="/usr/local/lib/gitea"
GITEA_BASE_DIR="/var/lib/gitea/data/gitea-repositories"
REPO_SUBDIR="gitea-demo"

# Target repositories from doc
TARGET_REPOS=(
    "${GITEA_BASE_DIR}/${REPO_SUBDIR}/web-app.git"
    "${GITEA_BASE_DIR}/${REPO_SUBDIR}/backend.git"
    "${GITEA_BASE_DIR}/${REPO_SUBDIR}/payment-service.git"
)

echo "=== Deploying Gitea Quota Server Hooks ==="

# 1. Create central hook directory
sudo mkdir -p "${CENTRAL_DIR}"

# 2. Copy hook files from local repository copy if available
if [[ -f "./scripts/quota-pre-receive" ]] && [[ -f "./scripts/quota-post-receive" ]]; then
    sudo cp ./scripts/quota-pre-receive "${CENTRAL_DIR}/quota-pre-receive"
    sudo cp ./scripts/quota-post-receive "${CENTRAL_DIR}/quota-post-receive"
fi

# 3. Apply central permissions and ownership
if [[ -f "${CENTRAL_DIR}/quota-pre-receive" ]] && [[ -f "${CENTRAL_DIR}/quota-post-receive" ]]; then
    sudo chown root:git "${CENTRAL_DIR}/quota-pre-receive" "${CENTRAL_DIR}/quota-post-receive"
    sudo chmod 750 "${CENTRAL_DIR}/quota-pre-receive" "${CENTRAL_DIR}/quota-post-receive"
    echo "[✓] Central hook scripts configured in ${CENTRAL_DIR}"
else
    echo "[!] Warning: Central hook scripts not found in ${CENTRAL_DIR}. Ensure files are placed there before running pushes."
fi

# 4. Loop through repositories and set up symlinks
for REPO in "${TARGET_REPOS[@]}"; do
    if [[ -d "${REPO}" ]]; then
        echo "Configuring: ${REPO}"

        # Create hook directories
        sudo mkdir -p "${REPO}/hooks/pre-receive.d" "${REPO}/hooks/post-receive.d"

        # Create z-quota symlinks
        sudo ln -sf "${CENTRAL_DIR}/quota-pre-receive" "${REPO}/hooks/pre-receive.d/z-quota"
        sudo ln -sf "${CENTRAL_DIR}/quota-post-receive" "${REPO}/hooks/post-receive.d/z-quota"

        # Fix directory permissions for gitea execution
        sudo chown -R git:git "${REPO}/hooks"

        echo "  [✓] Applied pre-receive and post-receive z-quota symlinks"
    else
        echo "  [!] Skipping: Path ${REPO} does not exist"
    fi
done

echo "=== Hook Installation Completed Complete ==="
