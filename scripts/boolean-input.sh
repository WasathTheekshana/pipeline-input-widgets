#!/usr/bin/env bash
# =============================================================================
# boolean-input.sh
# =============================================================================
# Demonstrates how to handle boolean-type workflow_dispatch inputs.
#
# Environment variables received from the workflow:
#   DRY_RUN           - "true" or "false". Skip real changes when true.
#   ENABLE_DEBUG      - "true" or "false". Enable verbose output when true.
#   NOTIFY_ON_COMPLETE - "true" or "false". Send notification when true.
#
# What this script teaches:
#   1. Boolean inputs arrive as the STRING "true" or "false" in shell —
#      NOT a real shell boolean. Always compare with == "true".
#   2. How to use a boolean to gate entire sections of a script.
#   3. How to combine multiple booleans for compound conditions.
#
# The workflow YAML also shows how to use booleans in workflow-level `if:`
# conditions — where they DO behave as real booleans (not strings).
# =============================================================================
set -euo pipefail

echo "=============================================="
echo "  GitHub Actions — Boolean Input Demo"
echo "=============================================="
echo ""
echo "Received inputs:"
echo "  DRY_RUN            : ${DRY_RUN}"
echo "  ENABLE_DEBUG       : ${ENABLE_DEBUG}"
echo "  NOTIFY_ON_COMPLETE : ${NOTIFY_ON_COMPLETE}"
echo ""

# =============================================================================
# SECTION 1: Enable debug mode early if requested
# =============================================================================
# set -x prints every command before it runs — useful for troubleshooting.
# Enable it early so ALL subsequent commands are traced.
# =============================================================================

echo "--- [Step 1] Configuring debug mode ---"

if [[ "${ENABLE_DEBUG}" == "true" ]]; then
  echo "🐛 Debug mode ENABLED — activating bash trace (set -x)."
  echo "   Every command below will be printed before execution."
  echo ""
  set -x   # From this point on, all commands are echoed
else
  echo "ℹ️  Debug mode is OFF. Set 'Enable verbose debug logging' to see trace output."
fi

echo ""

# =============================================================================
# SECTION 2: Dry run gate
# =============================================================================
# A dry run flag is one of the most common uses of boolean inputs.
# It lets users safely preview what WOULD happen without side effects.
# =============================================================================

echo "--- [Step 2] Deployment gate (dry_run check) ---"

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "🔍 DRY RUN mode is ON — simulating deployment steps (no real changes)."
  echo ""
  echo "  [SIMULATED] Pulling Docker image: my-app:latest"
  echo "  [SIMULATED] Applying Kubernetes manifests: kubectl apply -f k8s/"
  echo "  [SIMULATED] Waiting for rollout: kubectl rollout status deployment/my-app"
  echo "  [SIMULATED] Running smoke tests against staging URL"
  echo ""
  echo "✅ Dry run simulation complete. Review the steps above."
  echo "   Re-run the workflow with 'dry_run' unchecked to apply for real."

else
  echo "🚀 DRY RUN is OFF — executing real deployment steps."
  echo ""
  echo "  [RUNNING] Pulling Docker image..."
  echo "  [RUNNING] Applying Kubernetes manifests..."
  echo "  [RUNNING] Waiting for rollout to stabilize..."
  echo "  [RUNNING] Running smoke tests..."
  echo ""
  echo "✅ Deployment steps executed successfully."
fi

echo ""

# =============================================================================
# SECTION 3: Combining booleans for compound conditions
# =============================================================================
# You can combine multiple boolean inputs using standard bash operators:
#   &&  (AND) — both must be true
#   ||  (OR)  — at least one must be true
# =============================================================================

echo "--- [Step 3] Compound condition (dry_run AND debug) ---"

if [[ "${DRY_RUN}" == "true" && "${ENABLE_DEBUG}" == "true" ]]; then
  echo "🔍🐛 Both dry_run and debug are ON."
  echo "   This is ideal for troubleshooting your pipeline configuration"
  echo "   without risking any real infrastructure changes."

elif [[ "${DRY_RUN}" == "true" && "${ENABLE_DEBUG}" == "false" ]]; then
  echo "🔍 Dry run is ON, debug is OFF."
  echo "   You'll see simulated output only. Enable debug for more detail."

elif [[ "${DRY_RUN}" == "false" && "${ENABLE_DEBUG}" == "true" ]]; then
  echo "🐛 Real deployment with debug logging."
  echo "   Verbose output active — check logs carefully after the run."

else
  echo "✅ Standard deployment — no dry run, no extra debug output."
fi

echo ""

# =============================================================================
# SECTION 4: Optional notification step
# =============================================================================

echo "--- [Step 4] Completion notification ---"

if [[ "${NOTIFY_ON_COMPLETE}" == "true" ]]; then
  # Build a context-aware message depending on what actually happened
  if [[ "${DRY_RUN}" == "true" ]]; then
    NOTIFICATION_MSG="Dry run completed — no changes were applied."
  else
    NOTIFICATION_MSG="Deployment completed successfully."
  fi

  echo "🔔 Sending notification..."
  echo "   Message : '${NOTIFICATION_MSG}'"
  echo "   (In a real pipeline: POST to Slack/Teams webhook, send email, etc.)"
else
  echo "🔕 Notifications are disabled for this run."
fi

echo ""
echo "=============================================="
echo "✅ Boolean input demo complete."
echo "   dry_run            : ${DRY_RUN}"
echo "   enable_debug       : ${ENABLE_DEBUG}"
echo "   notify_on_complete : ${NOTIFY_ON_COMPLETE}"
echo "=============================================="
