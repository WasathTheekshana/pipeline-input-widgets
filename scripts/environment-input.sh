#!/usr/bin/env bash
# =============================================================================
# environment-input.sh
# =============================================================================
# Demonstrates how to handle environment-type workflow_dispatch inputs.
#
# Environment variables received from the workflow:
#   TARGET_ENVIRONMENT - The name of the selected GitHub Environment
#                        (e.g. development, staging, production)
#
# What this script teaches:
#   1. The environment input type populates its dropdown from GitHub
#      Environments configured in repo settings — not from the YAML
#   2. The selected name is just a string in the script, but the workflow
#      uses it to apply the environment's protection rules (approvals, etc.)
#   3. How to write environment-aware deployment logic using the name
#
# IMPORTANT:
#   The real power of the `environment` input type is NOT the string value —
#   it is that the workflow automatically applies the selected environment's
#   protection rules, secrets, and variables before ANY step runs.
#
#   For example:
#     - production might require 2 reviewers to approve before the job runs
#     - staging might have a 5-minute wait timer
#     - Each environment can have its own scoped secrets (DB_PASSWORD, API_KEY)
#
#   That gate happens BEFORE this script ever executes.
# =============================================================================
set -euo pipefail

echo "=============================================="
echo "  GitHub Actions — Environment Input Demo"
echo "=============================================="
echo ""
echo "Received inputs:"
echo "  TARGET_ENVIRONMENT : ${TARGET_ENVIRONMENT}"
echo ""

# =============================================================================
# SECTION 1: Validate the environment value
# =============================================================================
# Even though GitHub populates the dropdown from configured environments,
# someone could trigger this workflow via API with an arbitrary value.
# =============================================================================

echo "--- [Step 1] Validating target environment ---"

case "${TARGET_ENVIRONMENT}" in
  development|staging|production)
    echo "✅ Target environment '${TARGET_ENVIRONMENT}' is recognized."
    ;;
  *)
    echo "❌ ERROR: Unknown environment '${TARGET_ENVIRONMENT}'."
    echo "   Expected one of: development | staging | production"
    echo ""
    echo "   If you added a new environment, update this script's validation."
    exit 1
    ;;
esac

echo ""

# =============================================================================
# SECTION 2: Environment-specific configuration
# =============================================================================
# Each environment gets its own configuration: log level, replicas, domain,
# and whether to pause for confirmation before destructive operations.
# =============================================================================

echo "--- [Step 2] Loading environment configuration ---"

case "${TARGET_ENVIRONMENT}" in

  development)
    echo "🛠️  Environment: DEVELOPMENT"
    echo "   Purpose: Feature development and rapid iteration."
    echo "   Changes are applied immediately with no approval gates."
    echo ""
    ENV_LOG_LEVEL="debug"
    ENV_REPLICAS=1
    ENV_DOMAIN="dev.my-app.internal"
    ENV_AUTO_APPROVE=true
    ENV_ROLLBACK_ON_FAILURE=false
    ;;

  staging)
    echo "🧪 Environment: STAGING"
    echo "   Purpose: Pre-production validation and QA testing."
    echo "   Mirrors production configuration but uses test data."
    echo ""
    ENV_LOG_LEVEL="info"
    ENV_REPLICAS=2
    ENV_DOMAIN="staging.my-app.com"
    ENV_AUTO_APPROVE=true
    ENV_ROLLBACK_ON_FAILURE=true
    ;;

  production)
    echo "🚀 Environment: PRODUCTION"
    echo "   Purpose: Live environment serving real users."
    echo "   ⚠️  All changes here have direct user impact."
    echo "   (Protection rules on this environment require reviewer approval"
    echo "    BEFORE this workflow job is allowed to run.)"
    echo ""
    ENV_LOG_LEVEL="warn"
    ENV_REPLICAS=5
    ENV_DOMAIN="my-app.com"
    ENV_AUTO_APPROVE=false
    ENV_ROLLBACK_ON_FAILURE=true
    ;;

esac

echo "   Configuration loaded:"
echo "     Log level          : ${ENV_LOG_LEVEL}"
echo "     Replicas           : ${ENV_REPLICAS}"
echo "     Domain             : ${ENV_DOMAIN}"
echo "     Auto approve       : ${ENV_AUTO_APPROVE}"
echo "     Rollback on failure: ${ENV_ROLLBACK_ON_FAILURE}"
echo ""

# =============================================================================
# SECTION 3: Environment-specific deployment steps
# =============================================================================

echo "--- [Step 3] Running deployment steps for ${TARGET_ENVIRONMENT} ---"
echo ""

# Step 3a: Pre-deployment checks (stricter for higher environments)
echo "  [3a] Pre-deployment checks..."

if [[ "${TARGET_ENVIRONMENT}" == "production" ]]; then
  echo "       Running full production checklist:"
  echo "         ✅ Change freeze check — no active freeze window"
  echo "         ✅ Backup verification — latest backup is < 1 hour old"
  echo "         ✅ Rollback plan confirmed"
  echo "         ✅ On-call engineer notified"
elif [[ "${TARGET_ENVIRONMENT}" == "staging" ]]; then
  echo "       Running staging checklist:"
  echo "         ✅ QA sign-off confirmed"
  echo "         ✅ Integration tests passed"
else
  echo "       Development — skipping extended pre-checks."
fi

echo ""

# Step 3b: Deploy
echo "  [3b] Deploying application..."
echo "       Target  : ${ENV_DOMAIN}"
echo "       Replicas: ${ENV_REPLICAS}"
echo "       (Simulated — in a real pipeline: helm upgrade / kubectl apply)"
echo ""

# Step 3c: Post-deployment actions
echo "  [3c] Post-deployment actions..."

if [[ "${ENV_ROLLBACK_ON_FAILURE}" == "true" ]]; then
  echo "       Auto-rollback is ENABLED for ${TARGET_ENVIRONMENT}."
  echo "       If smoke tests fail, the previous version will be restored."
else
  echo "       Auto-rollback is DISABLED for ${TARGET_ENVIRONMENT}."
  echo "       Failed deploys require manual intervention."
fi

echo ""

# =============================================================================
# SECTION 4: Show how environment-scoped secrets would be used
# =============================================================================
# Each GitHub Environment can have its own secrets. They are automatically
# injected when `environment:` is set in the workflow job.
# The script doesn't set them — GitHub does.
# =============================================================================

echo "--- [Step 4] Environment-scoped secrets (illustrative) ---"
echo ""
echo "   In the workflow YAML, the job declares:"
echo "     environment: \${{ inputs.target_environment }}"
echo ""
echo "   This means GitHub automatically injects secrets scoped"
echo "   to '${TARGET_ENVIRONMENT}' — for example:"
echo "     DB_PASSWORD  → the ${TARGET_ENVIRONMENT} database password"
echo "     API_KEY      → the ${TARGET_ENVIRONMENT} API key"
echo ""
echo "   These secrets are NOT shared across environments, which prevents"
echo "   a dev deployment from accidentally using production credentials."
echo ""

echo "=============================================="
echo "✅ Environment input demo complete."
echo "   Environment : ${TARGET_ENVIRONMENT}"
echo "   Domain      : ${ENV_DOMAIN}"
echo "   Replicas    : ${ENV_REPLICAS}"
echo "=============================================="
