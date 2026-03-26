# GitHub Actions `workflow_dispatch` Input Types

A hands-on reference repo for all **5 input types** available in GitHub Actions
`workflow_dispatch` triggers. Each workflow is self-contained — fork the repo,
trigger a workflow from the Actions tab, and read the output to see exactly how
each input type behaves.

---

## CI Status

| Input Type | Workflow | Status |
|---|---|---|
| String | 01 - String Input Demo | [![String Input](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/01-string-input.yml/badge.svg)](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/01-string-input.yml) |
| Number | 02 - Number Input Demo | [![Number Input](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/02-number-input.yml/badge.svg)](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/02-number-input.yml) |
| Boolean | 03 - Boolean Input Demo | [![Boolean Input](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/03-boolean-input.yml/badge.svg)](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/03-boolean-input.yml) |
| Choice | 04 - Choice Input Demo | [![Choice Input](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/04-choice-input.yml/badge.svg)](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/04-choice-input.yml) |
| Environment | 05 - Environment Input Demo | [![Environment Input](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/05-environment-input.yml/badge.svg)](https://github.com/WasathTheekshana/pipeline-input-widgets/actions/workflows/05-environment-input.yml) |

---

## What is `workflow_dispatch`?

`workflow_dispatch` is a GitHub Actions trigger that lets you run a workflow
manually from the Actions tab (or via the GitHub API / `gh` CLI). You can
attach **typed input fields** to the trigger so the person running it can
pass parameters — similar to function arguments for your pipeline.

```yaml
on:
  workflow_dispatch:
    inputs:
      my_input:
        description: "Describe what this field does"
        type: string          # string | number | boolean | choice | environment
        required: true
        default: "hello"
```

There are **5 input types**. This repo has one workflow and one bash script
demonstrating each one.

---

## Input Types at a Glance

| Type | UI widget | Value in shell | Best for |
|---|---|---|---|
| `string` | Text field | Any text | Names, tags, messages |
| `number` | Number field | String — validate yourself | Counts, timeouts, ports |
| `boolean` | Checkbox | `"true"` or `"false"` | Dry-run, debug flags |
| `choice` | Dropdown | One of the listed options | Log levels, strategies |
| `environment` | Dropdown | A GitHub Environment name | Deployment targets |

---

## 01 — String Input

**File:** `.github/workflows/01-string-input.yml` · `scripts/string-input.sh`

A `string` input renders as a plain text field. It can be required or optional,
and supports a default value.

```yaml
inputs:
  app_name:
    description: "Application name to deploy"
    type: string
    required: true           # User must fill this in

  version_tag:
    description: "Version tag (e.g. v1.2.3 or latest)"
    type: string
    required: false
    default: "latest"        # Used when the field is left blank
```

**What the script demonstrates:**
- Checking for an empty required string with `-z`
- Validating a string against a pattern using bash regex (`=~`)
- Detecting when an optional field was left blank vs filled in

**Try it:**
Go to **Actions → 01 - String Input Demo → Run workflow** and experiment with:
- Leaving `version_tag` blank (uses the default)
- Setting `version_tag` to `v2.0.1` (valid semver)
- Setting `version_tag` to `my-custom-tag` (passes but shows a warning)

---

## 02 — Number Input

**File:** `.github/workflows/02-number-input.yml` · `scripts/number-input.sh`

A `number` input renders as a numeric text field. GitHub validates that the
value is a number before the workflow runs — but it still arrives in your
shell script as a **string**. Always validate and cast it yourself.

```yaml
inputs:
  replica_count:
    description: "Number of replicas (1–10)"
    type: number
    required: true
    default: 2

  timeout_seconds:
    description: "Deployment timeout in seconds (30–600)"
    type: number
    required: false
    default: 120
```

**What the script demonstrates:**
- Re-validating that the value is numeric using `=~ ^[0-9]+$`
- Enforcing min/max limits that the UI does not enforce
- Integer arithmetic with `(( ))` — e.g. converting seconds to minutes
- Branching logic based on numeric ranges

**Try it:**
Go to **Actions → 02 - Number Input Demo → Run workflow** and experiment with:
- `replica_count: 1` (shows an HA warning)
- `replica_count: 11` (fails boundary check)
- `timeout_seconds: 25` (fails minimum check)

---

## 03 — Boolean Input

**File:** `.github/workflows/03-boolean-input.yml` · `scripts/boolean-input.sh`

A `boolean` input renders as a **checkbox**. It is the most nuanced type because
it behaves differently depending on where you use it.

```yaml
inputs:
  dry_run:
    description: "Simulate without making real changes"
    type: boolean
    required: false
    default: false

  enable_debug:
    description: "Enable verbose debug logging"
    type: boolean
    required: false
    default: false
```

> **Important:** In the workflow YAML `if:` conditions, boolean inputs behave
> as real booleans. In shell scripts, they arrive as the **string** `"true"` or
> `"false"`. Always compare with `== "true"`, never treat them as shell booleans.

**What the script demonstrates:**
- Gating destructive operations behind a dry-run flag
- Activating `set -x` (bash trace) when debug mode is on
- Combining two booleans with `&&` and `||` for compound conditions
- Context-aware output that changes based on the combination of flags

**What the workflow demonstrates:**
- Using `if: ${{ inputs.dry_run == false }}` to control which **steps** run

**Try it:**
Go to **Actions → 03 - Boolean Input Demo → Run workflow** and experiment with:
- Check `dry_run` only — see simulated steps
- Check `enable_debug` only — see bash trace output (`set -x`)
- Check both — see verbose dry-run simulation

---

## 04 — Choice Input

**File:** `.github/workflows/04-choice-input.yml` · `scripts/choice-input.sh`

A `choice` input renders as a **dropdown** populated with options you define
directly in the YAML. GitHub validates that the submitted value is one of the
listed options — no free text is accepted via the UI.

```yaml
inputs:
  log_level:
    description: "Log verbosity level"
    type: choice
    required: true
    default: "info"          # Must match one of the options exactly
    options:
      - debug
      - info
      - warn
      - error

  deployment_strategy:
    description: "Rollout strategy"
    type: choice
    required: true
    default: "rolling"
    options:
      - rolling
      - blue-green
      - canary
      - recreate
```

**What the script demonstrates:**
- Using `case` statements for clean multi-branch logic
- Deriving secondary configuration variables from the user's selection
- Always including a `*)` catch-all for API/CLI-triggered runs
- Producing a formatted summary table from multiple choice inputs

**Try it:**
Go to **Actions → 04 - Choice Input Demo → Run workflow** and experiment with:
- `log_level: debug` + `deployment_strategy: canary` (see canary traffic weight)
- `log_level: error` + `deployment_strategy: recreate` (see downtime warning)

---

## 05 — Environment Input

**File:** `.github/workflows/05-environment-input.yml` · `scripts/environment-input.sh`

A `environment` input renders as a **dropdown populated from your repo's
configured GitHub Environments** (Settings → Environments). Unlike `choice`,
the options are not hardcoded in the YAML — they come from your repo settings.

```yaml
inputs:
  target_environment:
    description: "Target environment to deploy to"
    type: environment
    required: true

jobs:
  deploy:
    environment: ${{ inputs.target_environment }}  # applies protection rules
```

Setting `environment:` on the job is what makes this type powerful — it
automatically applies the selected environment's **protection rules** (required
reviewers, wait timers), **secrets**, and **variables** before any step runs.

**What the script demonstrates:**
- Environment-specific configuration (replicas, domain, log level)
- Stricter pre-deployment checks for higher environments
- How environment-scoped secrets work (each environment gets its own)

### Setup required before running workflow 05

This workflow needs GitHub Environments to exist in your repo. Without them,
the dropdown will be empty.

1. Go to your repo → **Settings → Environments**
2. Create three environments: `development`, `staging`, `production`
3. Optionally add protection rules to `staging` and `production`:
   - **Required reviewers** — someone must approve before the job runs
   - **Wait timer** — adds a delay before the job starts

**Try it:**
Go to **Actions → 05 - Environment Input Demo → Run workflow**, select an
environment, and observe how the script adjusts its behaviour per environment.
If you added a required reviewer to `production`, you will see an approval
gate appear before the job starts.

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── 01-string-input.yml
│       ├── 02-number-input.yml
│       ├── 03-boolean-input.yml
│       ├── 04-choice-input.yml
│       └── 05-environment-input.yml
└── scripts/
    ├── string-input.sh
    ├── number-input.sh
    ├── boolean-input.sh
    ├── choice-input.sh
    └── environment-input.sh
```

---

## Best Practices Shown in This Repo

- **Pass inputs via `env:`, not inline in `run:`** — prevents shell injection
- **Always re-validate in the script** — API/CLI callers can bypass UI validation
- **Boolean inputs are strings in shell** — always compare with `== "true"`
- **`case` with a `*)` catch-all** — defensive handling for unexpected values
- **`set -euo pipefail`** on every script — fail fast, no silent errors
- **`set -x` only when needed** — activate bash trace via a debug boolean flag
- **Environment input on the job** — lets GitHub inject scoped secrets/variables

---

## How to Trigger a Workflow

**From the GitHub UI:**
1. Go to the **Actions** tab
2. Select the workflow from the left sidebar
3. Click **Run workflow** (top right of the run list)
4. Fill in the inputs and click **Run workflow**

**From the `gh` CLI:**
```bash
gh workflow run 01-string-input.yml \
  -f app_name="my-api" \
  -f version_tag="v1.2.3" \
  -f deploy_message="Hotfix for login bug"
```

**From the GitHub REST API:**
```bash
curl -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/WasathTheekshana/pipeline-input-widgets/actions/workflows/01-string-input.yml/dispatches \
  -d '{"ref":"main","inputs":{"app_name":"my-api","version_tag":"v1.2.3"}}'
```
