#!/usr/bin/env bash
# =============================================================================
# number-input.sh
# =============================================================================
# Demonstrates how to handle number-type workflow_dispatch inputs.
#
# Environment variables received from the workflow:
#   REPLICA_COUNT   - Required. Integer between 1 and 10.
#   TIMEOUT_SECONDS - Optional. Integer between 30 and 600. Defaults to 120.
#
# What this script teaches:
#   1. How to validate that a value is actually numeric (belt-and-suspenders)
#   2. How to enforce min/max boundaries that the UI doesn't enforce
#   3. How to perform arithmetic and branch logic on numeric values
#
# IMPORTANT: GitHub Actions passes number inputs as STRINGS to shell scripts.
#            Always treat them as strings until you validate them yourself.
# =============================================================================
set -euo pipefail

echo "=============================================="
echo "  GitHub Actions — Number Input Demo"
echo "=============================================="
echo ""
echo "Received inputs:"
echo "  REPLICA_COUNT   : ${REPLICA_COUNT}"
echo "  TIMEOUT_SECONDS : ${TIMEOUT_SECONDS}"
echo ""

# =============================================================================
# SECTION 1: Validate inputs are actually numeric
# =============================================================================
# GitHub enforces this at the UI level, but if someone triggers the workflow
# via the API or gh CLI they could bypass it. Always re-validate.
# =============================================================================

echo "--- [Step 1] Validating input types ---"

if ! [[ "${REPLICA_COUNT}" =~ ^[0-9]+$ ]]; then
  echo "❌ ERROR: REPLICA_COUNT must be a positive integer. Got: '${REPLICA_COUNT}'"
  exit 1
fi

if ! [[ "${TIMEOUT_SECONDS}" =~ ^[0-9]+$ ]]; then
  echo "❌ ERROR: TIMEOUT_SECONDS must be a positive integer. Got: '${TIMEOUT_SECONDS}'"
  exit 1
fi

echo "✅ Both inputs are valid integers."
echo ""

# =============================================================================
# SECTION 2: Enforce boundary rules on REPLICA_COUNT
# =============================================================================
# The UI description says 1–10 but doesn't enforce it. We do it here.
# (( )) is used for integer arithmetic in bash.
# =============================================================================

echo "--- [Step 2] Boundary check — replica count ---"

if (( REPLICA_COUNT < 1 )); then
  echo "❌ ERROR: REPLICA_COUNT must be at least 1. Got: ${REPLICA_COUNT}"
  exit 1
fi

if (( REPLICA_COUNT > 10 )); then
  echo "❌ ERROR: REPLICA_COUNT cannot exceed 10. Got: ${REPLICA_COUNT}"
  echo "   Use a dedicated scaling tool for larger deployments."
  exit 1
fi

echo "✅ REPLICA_COUNT ${REPLICA_COUNT} is within the allowed range (1–10)."
echo ""

# =============================================================================
# SECTION 3: Conditional rendering based on replica count range
# =============================================================================

echo "--- [Step 3] Replica count assessment ---"

if (( REPLICA_COUNT == 1 )); then
  echo "⚠️  WARNING: Only 1 replica configured."
  echo "   There is NO high availability. A single pod failure means downtime."
  echo "   Recommendation: use at least 2 replicas in any shared environment."

elif (( REPLICA_COUNT <= 3 )); then
  echo "ℹ️  Low replica count (${REPLICA_COUNT})."
  echo "   Suitable for: development, feature branches, internal testing."

elif (( REPLICA_COUNT <= 7 )); then
  echo "ℹ️  Moderate replica count (${REPLICA_COUNT})."
  echo "   Suitable for: staging, UAT, low-traffic production."

else
  echo "ℹ️  High replica count (${REPLICA_COUNT})."
  echo "   Suitable for: production under significant load."
  echo "   Ensure your cluster has sufficient node capacity before proceeding."
fi

echo ""

# =============================================================================
# SECTION 4: Enforce boundary rules on TIMEOUT_SECONDS and derive minutes
# =============================================================================

echo "--- [Step 4] Boundary check — timeout ---"

if (( TIMEOUT_SECONDS < 30 )); then
  echo "❌ ERROR: TIMEOUT_SECONDS must be at least 30. Got: ${TIMEOUT_SECONDS}"
  exit 1
fi

if (( TIMEOUT_SECONDS > 600 )); then
  echo "❌ ERROR: TIMEOUT_SECONDS cannot exceed 600 (10 minutes). Got: ${TIMEOUT_SECONDS}"
  exit 1
fi

# Arithmetic: derive human-readable minutes
TIMEOUT_MINUTES=$(( TIMEOUT_SECONDS / 60 ))
REMAINING_SECONDS=$(( TIMEOUT_SECONDS % 60 ))

echo "✅ Timeout is valid: ${TIMEOUT_SECONDS}s (${TIMEOUT_MINUTES}m ${REMAINING_SECONDS}s)"
echo ""

# =============================================================================
# SECTION 5: Conditional warnings based on timeout value
# =============================================================================

echo "--- [Step 5] Timeout assessment ---"

if (( TIMEOUT_SECONDS < 60 )); then
  echo "⚠️  Short timeout (${TIMEOUT_SECONDS}s). May not be enough for image pulls and startup."
  echo "   Consider 120s as a safe minimum for most container workloads."

elif (( TIMEOUT_SECONDS <= 300 )); then
  echo "✅ Standard timeout (${TIMEOUT_SECONDS}s). Good for most deployments."

else
  echo "ℹ️  Extended timeout (${TIMEOUT_SECONDS}s). Expecting a long-running deployment."
  echo "   Ensure this is intentional — long timeouts can hide real issues."
fi

echo ""
echo "=============================================="
echo "✅ Number input demo complete."
echo "   Replicas : ${REPLICA_COUNT}"
echo "   Timeout  : ${TIMEOUT_SECONDS}s (${TIMEOUT_MINUTES}m ${REMAINING_SECONDS}s)"
echo "=============================================="
