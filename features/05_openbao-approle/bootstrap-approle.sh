#!/bin/bash
set -euo pipefail

# bootstrap-approle.sh — one-shot machine identity enrollment.
#
# Flow:
#   1. Operator SSHs into the server
#   2. Operator runs: bao login -method=oidc role=operator
#   3. Operator runs: bash bootstrap-approle.sh
#   4. Script creates an AppRole named after this host
#   5. Script stores role_id + secret_id in /etc/bao/
#   6. Script revokes the operator's token and wipes the token file
#
# After this, the server authenticates on its own via AppRole.
# No human token retained, no browser needed for future auth.

VAULT_ADDR="${VAULT_ADDR:-https://bao.hnatekmar.xyz}"
export VAULT_ADDR

BAO_CONF_DIR="/etc/bao"
ROLE_NAME="${1:-$(hostname)}"

# --- Pre-flight ---

bao token lookup >/dev/null 2>&1 || {
    echo "ERROR: No valid Bao token. Run 'bao login -method=oidc role=operator' first." >&2
    exit 1
}

mkdir -p "$BAO_CONF_DIR"

# --- Create AppRole for this machine ---

echo "==> Creating AppRole: $ROLE_NAME"

bao write "auth/approle/role/$ROLE_NAME" \
    token_policies="default" \
    token_ttl=1h \
    token_max_ttl=4h \
    secret_id_ttl=0 \
    secret_id_num_uses=0

# --- Store role_id ---

ROLE_ID=$(bao read -field=role_id "auth/approle/role/$ROLE_NAME/role-id")
echo "$ROLE_ID" > "$BAO_CONF_DIR/role-id"
chmod 0640 "$BAO_CONF_DIR/role-id"

# --- Store secret_id ---

SECRET_ID=$(bao write -f -field=secret_id "auth/approle/role/$ROLE_NAME/secret-id")
echo "$SECRET_ID" > "$BAO_CONF_DIR/secret-id"
chmod 0600 "$BAO_CONF_DIR/secret-id"

echo "==> Credentials written to $BAO_CONF_DIR/"

# --- Dispose of operator token ---

bao token revoke -self 2>/dev/null || true
rm -f ~/.bao-token
unset VAULT_TOKEN

echo "==> Operator token revoked. Server now uses AppRole '$ROLE_NAME'."
