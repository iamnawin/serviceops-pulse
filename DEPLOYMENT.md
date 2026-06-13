# ServiceOps Pulse — Deployment Guide

## 1. Project Deployment Overview

ServiceOps Pulse is a Salesforce DX source-format project. The metadata footprint:

| Layer | Metadata | Depends On |
|---|---|---|
| 1. Core | Entitlement Settings, 2 Custom Objects, 2 Custom Metadata Types, all fields, 9 CMDT records | nothing |
| 2. Code | 22 Apex classes, 5 LWC bundles | Core (objects, fields, Entitlement Management) |
| 3. FlexiPages | 4 App Pages | Code (each page embeds one LWC) |
| 4. UI | 4 Custom Tabs | FlexiPages (all tabs are Lightning Page tabs) |
| 5. App | ServiceOps_Pulse Custom Application | UI (app navigation lists all 4 tabs) |
| 6. Security | 3 Permission Sets | App, Tabs, Apex classes, Objects, Fields |
| 7. Full | Everything above | — (final validation) |

> **Why FlexiPages are NOT last in this project:** all four Custom Tabs are
> *Lightning Page tabs* (`<flexiPage>` reference), not object tabs. A tab cannot
> exist without its FlexiPage, the app cannot exist without its tabs, and the
> permission sets reference the app. The layer order above follows the real
> dependency chain.

> **Critical org prerequisite — Entitlement Management:** `SLAPulseEngine.cls`
> and `ServiceOpsTestDataFactory.cls` reference the `Entitlement` and
> `CaseMilestone` sObjects and `Case.EntitlementId`. These only exist when
> Entitlement Management is enabled in the target org. The core layer deploys
> `settings/Entitlement.settings-meta.xml` to enable it. If you skip the core
> layer on a fresh org, **every Apex class will fail to compile** and you will
> see dozens of cascading errors.

There are **no Profiles** in this source — access is granted exclusively via
permission sets (`ServiceOps_Admin`, `ServiceOps_Manager`, `ServiceOps_Agent`).

## 2. Prerequisites

- Salesforce CLI (`sf`) v2.x
- Git
- A target org: Developer Edition, sandbox, or scratch org (Dev Hub required for scratch only)
- Target org must support Entitlement Management (Developer Edition, and Enterprise+ sandboxes do)
- Windows: PowerShell 5.1+ — macOS/Linux: bash

## 3. Salesforce CLI Version Check

```
sf --version
```

If you still have the legacy `sfdx` CLI, install the new one: `npm install --global @salesforce/cli`.

## 4. Mac Setup

```bash
brew install node        # if Node.js is missing
npm install --global @salesforce/cli
git clone <repo-url> && cd "ServiceOps Pulse"
```

## 5. Windows Setup

```powershell
winget install Salesforce.sf   # or: npm install --global @salesforce/cli
git clone <repo-url>; cd "ServiceOps Pulse"
```

If PowerShell blocks the scripts: `Set-ExecutionPolicy -Scope Process RemoteSigned`.

## 6. Authenticate to Salesforce Org

```
sf org login web --alias ServiceCloud
sf org list
sf org display --target-org ServiceCloud
```

## 7. Check if Org is a Dev Hub

```
sf org list
```

Dev Hub orgs appear under "DevHubs". Or check directly:

```
sf data query --query "SELECT Id FROM ScratchOrgInfo LIMIT 1" --target-org ServiceCloud
```

If this errors with `sObject type 'ScratchOrgInfo' is not supported`, the org is
**not** a Dev Hub — skip scratch orgs and deploy directly (sections 9–11).

## 8. Scratch Org Creation (only if Dev Hub is available)

```
sf org create scratch --definition-file config/project-scratch-def.json --target-dev-hub <DevHubAlias> --alias myScratchOrg --duration-days 7 --set-default
sf project deploy start --source-dir force-app --target-org myScratchOrg
```

The scratch definition already enables the `Entitlements` feature, so a single
source push works there.

## 9. Normal Developer/Sandbox Org Deployment

For a **first deployment to a fresh org**, use the layered scripts — they enable
Entitlement Management (core layer) before the code layer compiles:

Mac/Linux:

```bash
bash scripts/deploy-all.sh ServiceCloud
```

Windows:

```powershell
.\scripts\deploy-all.ps1 -OrgAlias ServiceCloud
```

Once the org has all layers (or at minimum Entitlement Management enabled), a
single full deploy also works:

```
sf project deploy start --target-org ServiceCloud --manifest manifest/package-full.xml --verbose
sf project deploy start --target-org ServiceCloud --source-dir force-app --verbose
```

## 10. Layered Validation

Validate (check-only, nothing is saved) per layer:

```
sf project deploy start --target-org ServiceCloud --manifest manifest/package-core.xml --dry-run --verbose
sf project deploy start --target-org ServiceCloud --manifest manifest/package-code.xml --dry-run --verbose
sf project deploy start --target-org ServiceCloud --manifest manifest/package-flexipages.xml --dry-run --verbose
sf project deploy start --target-org ServiceCloud --manifest manifest/package-ui.xml --dry-run --verbose
sf project deploy start --target-org ServiceCloud --manifest manifest/package-app.xml --dry-run --verbose
sf project deploy start --target-org ServiceCloud --manifest manifest/package-security.xml --dry-run --verbose
sf project deploy start --target-org ServiceCloud --manifest manifest/package-full.xml --dry-run --verbose
```

Or all at once — Mac: `bash scripts/validate-all.sh ServiceCloud` — Windows:
`.\scripts\validate-all.ps1 -OrgAlias ServiceCloud`.

> **Important:** `--dry-run` persists nothing. On a *fresh* org, layer 2+
> validation fails because layer 1 was only validated, never saved. Layered
> validation is meaningful against an org that already has the previous layers
> deployed. On a fresh org go straight to `deploy-all`, or validate only
> `package-core.xml` and `package-full.xml`.

## 11. Layered Deployment

Each layer individually (same order as the table in section 1):

```
bash scripts/deploy-core.sh ServiceCloud         # .\scripts\deploy-core.ps1 -OrgAlias ServiceCloud
bash scripts/deploy-code.sh ServiceCloud
bash scripts/deploy-flexipages.sh ServiceCloud
bash scripts/deploy-ui.sh ServiceCloud
bash scripts/deploy-app.sh ServiceCloud
bash scripts/deploy-security.sh ServiceCloud
bash scripts/validate-full.sh ServiceCloud       # final check: everything is consistent
```

Or in one shot: `bash scripts/deploy-all.sh ServiceCloud` /
`.\scripts\deploy-all.ps1 -OrgAlias ServiceCloud`.

## 12. FlexiPage Troubleshooting

All four FlexiPages are App Pages using `flexipage:defaultAppHomeTemplate` and
each embeds exactly one local LWC:

| FlexiPage | LWC |
|---|---|
| ServiceOps_Pulse_Home | serviceOpsHome |
| Queue_Risk_Board | queuePulseBoard |
| Reply_Risk_Board | replyPulseBoard |
| ServiceOps_Setup | serviceOpsSetupWizard |

If a FlexiPage fails with *"Component [name] not found"*, the LWC layer was not
deployed first — run `deploy-code` before `deploy-flexipages`. The LWC
`js-meta.xml` must expose the `lightning__AppPage` target (all four do).

## 13. App Visibility Troubleshooting

`ServiceOps_Pulse.app-meta.xml` references the four tabs above and nothing else
(no utility bar, no logo asset, no profile action overrides). If the app deploy
fails with *"Invalid tab [name]"*, deploy FlexiPages → Tabs first. After
deployment, users see the app only if they hold one of the permission sets
(Agent has `visible=false` for the app by design).

## 14. Permission Set Troubleshooting

The permission sets reference: the app, all 4 tabs, 2 Apex controllers
(`ServiceOpsDashboardController`, `ServiceOpsSetupController`), both custom
objects + all fields, and both custom metadata types. They must deploy **last**.

Known failure modes:

- *"Unknown user permission"* / *"row size too large"* — wrong API version; keep `62.0`.
- *Duplicate `objectPermissions`/`fieldPermissions`* — each object/field may
  appear only once per permission set file. (This was a real bug in this repo,
  fixed in this cleanup — see section 15.)
- *"Permission set requires Entitlement..."* — deploy the core layer first.

Assign after deployment:

```
sf org assign permset --name ServiceOps_Admin --target-org ServiceCloud
```

## 15. Common Error Examples and Fixes

| Error | Root Cause | Fix |
|---|---|---|
| `Invalid type: CaseMilestone` / `Invalid type: Entitlement` on many classes | Entitlement Management not enabled in target org | Deploy `package-core.xml` first (contains `Entitlement.settings-meta.xml`), or enable Setup → Entitlement Settings manually |
| `No such column 'EntitlementId' on entity 'Case'` | Same as above | Same as above |
| Duplicate object/field permissions in permission set | Duplicated XML blocks (was present in all 3 permission sets before this cleanup) | Keep one block per object/field |
| `Invalid tab ServiceOps_Pulse_Home` on CustomApplication | Tabs not deployed yet | Deploy ui layer before app layer |
| `Component serviceOpsHome not found` on FlexiPage | LWC not deployed yet | Deploy code layer before flexipages layer |
| `In field: application - no CustomApplication named ServiceOps_Pulse found` on PermissionSet | App not deployed yet | Deploy app layer before security layer |

### If deployment fails, do not randomly edit XML

Run the failing layer directly and capture the full component-level errors:

```
sf project deploy start --target-org ServiceCloud --manifest manifest/package-flexipages.xml --dry-run --verbose
```

Then record: metadata file name, component type, error message, the missing
dependency, and whether the error is object, field, tab, app, LWC, permission,
or settings related. Fix the dependency (usually: deploy the earlier layer),
not the referencing XML.

## Running Apex Tests

```
sf apex run test --target-org ServiceCloud --test-level RunLocalTests --code-coverage --result-format human --wait 20
```

## Post-Deployment Manual Setup

Metadata deployment alone is not enough to see data:

1. **Assign a permission set** to your user (section 14).
2. **CMDT records ship in source** (`force-app/main/default/customMetadata`):
   `ServiceOps_Setting.Default` (active, default thresholds) plus 8
   `ServiceOps_Risk_Rule` records (4 Reply Risk tiers, 3 Queue Risk tiers,
   1 SLA missing-entitlement rule). Adjust thresholds in Setup → Custom
   Metadata Types → Manage Records if the defaults don't fit.
3. **Schedule the scan**: Execute Anonymous →
   `ServiceOpsScanScheduler.scheduleJob(60);` (or via the ServiceOps Setup tab wizard).
4. Optional: set `Enable_Entitlement_Risk__c = true` once entitlement data exists.
