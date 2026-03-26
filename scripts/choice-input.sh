#!/usr/bin/env bash
# =============================================================================
# choice-input.sh
# =============================================================================
# Demonstrates how to handle choice-type workflow_dispatch inputs.
#
# Environment variables received from the workflow:
#   LOG_LEVEL           - One of: debug | info | warn | error
#   DEPLOYMENT_STRATEGY - One of: rolling | blue-green | canary | recreate
#
# What this script teaches:
#   1. Use `case` statements for clean multi-branch logic on choice inputs
#   2. Always include a catch-all `*)` case — even though GitHub validates
#      the choice, the workflow can also be triggered via API/CLI with
#      arbitrary values
#   3. How to derive configuration variables from a user's choice and
#      use them downstream in the same script
# =============================================================================
set -euo pipefail

echo "=============================================="
echo "  GitHub Actions — Choice Input Demo"
echo "=============================================="
echo ""
echo "Received inputs:"
echo "  LOG_LEVEL           : ${LOG_LEVEL}"
echo "  DEPLOYMENT_STRATEGY : ${DEPLOYMENT_STRATEGY}"
echo ""

# =============================================================================
# SECTION 1: Configure logging based on log level choice
# =============================================================================
# Each choice produces a different configuration. We derive secondary
# variables (LOG_FORMAT, LOG_RETENTION_DAYS) from the user's selection
# and use them later in the script.
# =============================================================================

echo "--- [Step 1] Log level configuration ---"

case "${LOG_LEVEL}" in

  debug)
    echo "🐛 Log level: DEBUG"
    echo "   All events will be logged — including low-level internals."
    echo "   ⚠️  Debug logs may contain sensitive data. Use only in dev/staging."
    LOG_FORMAT="json"
    LOG_RETENTION_DAYS=3
    ;;

  info)
    echo "ℹ️  Log level: INFO"
    echo "   Standard operational events will be logged."
    echo "   Recommended for most environments."
    LOG_FORMAT="json"
    LOG_RETENTION_DAYS=7
    ;;

  warn)
    echo "⚠️  Log level: WARN"
    echo "   Only warnings and errors will be captured."
    echo "   Good for high-throughput services where info logs are too noisy."
    LOG_FORMAT="text"
    LOG_RETENTION_DAYS=14
    ;;

  error)
    echo "🔴 Log level: ERROR"
    echo "   Minimal logging — errors only."
    echo "   Ensure you have a separate alerting/monitoring system in place."
    LOG_FORMAT="text"
    LOG_RETENTION_DAYS=30
    ;;

  *)
    # This should never happen for choice inputs triggered via the UI,
    # but can happen when the workflow is triggered via the API or gh CLI.
    echo "❌ ERROR: Unknown log level '${LOG_LEVEL}'."
    echo "   Allowed values: debug | info | warn | error"
    exit 1
    ;;

esac

echo ""
echo "   Derived configuration:"
echo "     LOG_FORMAT          : ${LOG_FORMAT}"
echo "     LOG_RETENTION_DAYS  : ${LOG_RETENTION_DAYS} days"
echo ""

# =============================================================================
# SECTION 2: Configure deployment strategy
# =============================================================================
# Each strategy has different operational implications. The script explains
# what each one does and what settings it would apply in a real pipeline.
# =============================================================================

echo "--- [Step 2] Deployment strategy configuration ---"

case "${DEPLOYMENT_STRATEGY}" in

  rolling)
    echo "🔄 Strategy: ROLLING UPDATE"
    echo "   Gradually replaces old pods with new ones."
    echo "   ✅ Zero downtime"
    echo "   ⚠️  Brief period where both old and new versions serve traffic"
    echo "   ✅ Safe for stateless applications"
    echo ""
    MAX_SURGE=1
    MAX_UNAVAILABLE=0
    echo "   Kubernetes settings:"
    echo "     strategy.rollingUpdate.maxSurge        : ${MAX_SURGE}"
    echo "     strategy.rollingUpdate.maxUnavailable  : ${MAX_UNAVAILABLE}"
    ;;

  blue-green)
    echo "🔵🟢 Strategy: BLUE-GREEN DEPLOYMENT"
    echo "   A full parallel environment (green) is provisioned alongside"
    echo "   the existing one (blue). Traffic is switched atomically."
    echo "   ✅ Instant rollback — just point traffic back to blue"
    echo "   ✅ Zero downtime"
    echo "   ⚠️  Requires 2x infrastructure temporarily (higher cost)"
    echo ""
    echo "   Steps this strategy would execute:"
    echo "     1. Deploy new version to green environment"
    echo "     2. Run smoke tests against green"
    echo "     3. Switch load balancer to green"
    echo "     4. Monitor for 10 minutes"
    echo "     5. Decommission blue environment"
    ;;

  canary)
    echo "🐤 Strategy: CANARY DEPLOYMENT"
    echo "   Routes a small slice of real traffic to the new version first."
    echo "   Monitor metrics before gradually increasing the percentage."
    echo "   ✅ Reduces blast radius of bad releases"
    echo "   ✅ Real traffic validates the new version"
    echo "   ⚠️  Slightly more complex rollback procedure"
    echo ""
    CANARY_INITIAL_WEIGHT=10
    CANARY_PROMOTE_AFTER_MINUTES=15
    echo "   Canary settings:"
    echo "     Initial traffic weight   : ${CANARY_INITIAL_WEIGHT}%"
    echo "     Promote to 100% after   : ${CANARY_PROMOTE_AFTER_MINUTES} minutes"
    echo "     Rollback trigger        : error rate > 1% OR latency p99 > 2s"
    ;;

  recreate)
    echo "🔁 Strategy: RECREATE"
    echo "   All existing pods are terminated BEFORE new ones are started."
    echo "   ❌ Causes downtime — all traffic is interrupted during the gap"
    echo "   ✅ Useful for stateful apps that cannot run two versions in parallel"
    echo "   ✅ Simplest rollout — no overlap to manage"
    echo ""
    ESTIMATED_DOWNTIME_SECONDS=45
    echo "   ⚠️  Estimated downtime: ~${ESTIMATED_DOWNTIME_SECONDS} seconds"
    echo "   Recommended: schedule during a maintenance window"
    ;;

  *)
    echo "❌ ERROR: Unknown deployment strategy '${DEPLOYMENT_STRATEGY}'."
    echo "   Allowed values: rolling | blue-green | canary | recreate"
    exit 1
    ;;

esac

echo ""

# =============================================================================
# SECTION 3: Combine both choices for a final deployment plan summary
# =============================================================================

echo "--- [Step 3] Final deployment plan ---"
echo ""
echo "  ┌──────────────────────────────────────────────┐"
echo "  │  Deployment Plan Summary                     │"
echo "  ├──────────────────────────────────────────────┤"
printf "  │  %-20s : %-23s│\n" "Log Level"   "${LOG_LEVEL}"
printf "  │  %-20s : %-23s│\n" "Log Format"  "${LOG_FORMAT}"
printf "  │  %-20s : %-23s│\n" "Retention"   "${LOG_RETENTION_DAYS} days"
printf "  │  %-20s : %-23s│\n" "Strategy"    "${DEPLOYMENT_STRATEGY}"
echo "  └──────────────────────────────────────────────┘"

echo ""
echo "=============================================="
echo "✅ Choice input demo complete."
echo "   Log level  : ${LOG_LEVEL}"
echo "   Strategy   : ${DEPLOYMENT_STRATEGY}"
echo "=============================================="
