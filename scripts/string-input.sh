#!/usr/bin/env bash
# =============================================================================
# string-input.sh
# =============================================================================
# Demonstrates how to handle string-type workflow_dispatch inputs.
#
# Environment variables received from the workflow:
#   APP_NAME       - Required. The application name.
#   VERSION_TAG    - Optional. Defaults to "latest".
#   DEPLOY_MESSAGE - Optional. Defaults to empty string.
#
# What this script teaches:
#   1. How to validate a required string input
#   2. How to detect when an optional string was left empty
#   3. How to branch logic based on string content and pattern matching
# =============================================================================
set -euo pipefail

# -----------------------------------------------------------------------------
# Print a header so the log output is easy to read in the GitHub Actions UI
# -----------------------------------------------------------------------------
echo "=============================================="
echo "  GitHub Actions — String Input Demo"
echo "=============================================="
echo ""
echo "Received inputs:"
echo "  APP_NAME       : ${APP_NAME}"
echo "  VERSION_TAG    : ${VERSION_TAG}"
echo "  DEPLOY_MESSAGE : ${DEPLOY_MESSAGE:-<not provided>}"
echo ""

# =============================================================================
# SECTION 1: Validate required string input
# =============================================================================
# Even though the workflow marks app_name as required, it's good practice to
# double-check in the script — especially when scripts are called from
# multiple places or tested locally.
# =============================================================================

echo "--- [Step 1] Validating required input ---"

if [[ -z "${APP_NAME}" ]]; then
  echo "❌ ERROR: APP_NAME is required but was not provided."
  exit 1
fi

echo "✅ APP_NAME is present: '${APP_NAME}'"
echo ""

# =============================================================================
# SECTION 2: Branch logic based on version tag value
# =============================================================================
# Demonstrates how to check if a string equals a specific value,
# and how to validate a string against a pattern (regex).
# =============================================================================

echo "--- [Step 2] Evaluating version tag ---"

if [[ "${VERSION_TAG}" == "latest" ]]; then
  # The user left the default — warn that this is not ideal for production
  echo "⚠️  VERSION_TAG is 'latest'."
  echo "   This is fine for development but avoid it in production."
  echo "   Tip: pin a specific version tag like v1.2.3 for reproducible deploys."

else
  # Check if the tag follows semantic versioning: vMAJOR.MINOR.PATCH
  if [[ "${VERSION_TAG}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "✅ VERSION_TAG '${VERSION_TAG}' is a valid semantic version."
    echo "   Proceeding with pinned version deployment."
  else
    echo "⚠️  VERSION_TAG '${VERSION_TAG}' does not match semver format (e.g. v1.2.3)."
    echo "   Proceeding, but consider enforcing the format in your workflow."
  fi
fi

echo ""

# =============================================================================
# SECTION 3: Conditional rendering based on an optional string
# =============================================================================
# When an optional string input is left blank, it arrives as an empty string.
# Use -z (zero length) to check for absence.
# =============================================================================

echo "--- [Step 3] Checking optional deploy message ---"

if [[ -z "${DEPLOY_MESSAGE}" ]]; then
  echo "ℹ️  No deploy message provided — skipping notification step."
else
  echo "📢 Deploy message detected. Attaching to deployment record..."
  echo ""
  echo "  ┌─────────────────────────────────────────┐"
  echo "  │ Deployment Message                       │"
  echo "  │                                          │"
  # Print each line of the message indented
  while IFS= read -r line; do
    printf "  │  %-40s│\n" "${line}"
  done <<< "${DEPLOY_MESSAGE}"
  echo "  └─────────────────────────────────────────┘"
fi

echo ""
echo "=============================================="
echo "✅ String input demo complete."
echo "   App    : ${APP_NAME}"
echo "   Version: ${VERSION_TAG}"
echo "=============================================="
