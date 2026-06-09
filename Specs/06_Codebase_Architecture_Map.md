# ServiceOps Pulse: Codebase Architecture & Source of Truth

This document serves as the master reference for the ServiceOps Pulse codebase. It outlines the dependency tree, execution flows, and the exact purpose of every Apex class and Lightning Web Component.

---

## 1. Directory & Class Structure (Tree)

```text
force-app/main/default/
├── classes/
│   ├── Controllers (LWC Integration)
│   │   ├── ServiceOpsDashboardController.cls
│   │   └── ServiceOpsSetupController.cls
│   ├── Automation (Scheduling & Batch)
│   │   ├── ServiceOpsScanScheduler.cls
│   │   └── ServiceOpsScanBatch.cls
│   ├── Services (Orchestration Layer)
│   │   ├── ReplyPulseService.cls
│   │   ├── QueuePulseService.cls
│   │   ├── SLAPulseService.cls
│   │   ├── ServiceOpsSetupService.cls
│   │   └── ServiceOpsSignalService.cls  <-- The DML & Metadata Engine
│   ├── Engines (Business Logic Layer)
│   │   ├── ReplyPulseEngine.cls
│   │   ├── QueuePulseEngine.cls
│   │   └── SLAPulseEngine.cls
│   ├── Evaluators (Math & Rules)
│   │   └── ServiceOpsSignalEvaluator.cls
│   ├── Shared / Utilities
│   │   └── ServiceOpsConstants.cls
│   └── Tests
│       ├── ServiceOpsTestDataFactory.cls
│       ├── ReplyPulseEngineTest.cls
│       ├── QueuePulseEngineTest.cls
│       ├── SLAPulseEngineTest.cls
│       ├── ServiceOpsDashboardCtrlTest.cls
│       ├── ServiceOpsSetupCtrlTest.cls
│       ├── ServiceOpsSignalEvaluatorTest.cls
│       └── ServiceOpsScanSchedulerTest.cls
└── lwc/
    ├── serviceOpsHome (Executive Summary Dashboard)
    ├── replyPulseBoard (Datatable for Reply Risks)
    ├── queuePulseBoard (Datatable for Queue Risks)
    ├── casePulseDetailPanel (Case Record Page Widget)
    └── serviceOpsSetupWizard (Admin Configuration)
```

---

## 2. Execution Flows & Call Hierarchy

### Flow A: The Automated Risk Scan (Batch Process)
How risks are detected automatically in the background.

1. **`ServiceOpsScanScheduler`** runs (e.g., hourly).
2. ↳ Calls `Database.executeBatch(new ServiceOpsScanBatch())`.
3. ↳ **`ServiceOpsScanBatch`** queries all Open Cases.
4.   ↳ Calls `ReplyPulseService.scanReplyRisks(caseIds)`.
5.     ↳ Calls `ReplyPulseEngine.processCases(caseIds)`.
6.       ↳ Queries `EmailMessage` history.
7.       ↳ Calls `ServiceOpsSignalEvaluator.evaluateRisk()` to check age against Custom Metadata rules.
8.       ↳ Calls `ServiceOpsSignalService.upsertSignals()` / `resolveSignals()` to save to DB.
9.   ↳ Calls `QueuePulseService.scanQueueRisks(caseIds)`.
10.    ↳ Calls `QueuePulseEngine` -> `Evaluator` -> `SignalService`.
11.  ↳ Calls `SLAPulseService.scanSlaRisks(caseIds)`.
12.    ↳ Calls `SLAPulseEngine` -> `Evaluator` -> `SignalService`.

### Flow B: User Views a Dashboard (LWC)
How managers see the data.

1. User opens **`serviceOpsHome`** or **`replyPulseBoard`**.
2. ↳ LWC calls `@wire(getExecutiveSummary)` or `@wire(getRiskyCases)` in **`ServiceOpsDashboardController`**.
3.   ↳ Controller executes `WITH USER_MODE` SOQL against `ServiceOps_Case_Signal__c`.
4.   ↳ Returns `AggregateResult` or List of Signals back to the UI.

### Flow C: Admin Configures the App (Setup Wizard)
How settings are safely stored.

1. Admin uses **`serviceOpsSetupWizard`**.
2. ↳ LWC calls `ServiceOpsSetupController.saveSettings()`.
3.   ↳ Calls `ServiceOpsSetupService.saveSettings()`.
4.     ↳ Uses `Metadata.CustomMetadata` and `Metadata.Operations.enqueueDeployment()` to natively update the `ServiceOps_Setting__mdt` record.

---

## 3. Class Dictionary (The "What Does It Do?")

### Controllers
*   **`ServiceOpsDashboardController.cls`**: The only class LWCs talk to for dashboard data. Contains methods to get aggregate counts (Executive Summary) and detailed lists of risky cases.
*   **`ServiceOpsSetupController.cls`**: Acts as a bridge between the LWC Setup Wizard and the Metadata deployment service.

### Services (The Orchestrators)
*   **`ServiceOpsSignalService.cls`**: **CRITICAL CLASS.** This is the *only* class allowed to perform DML on the `ServiceOps_Case_Signal__c` object or fetch Custom Metadata. It handles de-duplication of signals and enforces `WITH USER_MODE` security. It also houses the `@TestVisible` static variables used for mocking metadata during tests.
*   **`ReplyPulseService.cls`**, **`QueuePulseService.cls`**, **`SLAPulseService.cls`**: Thin wrappers that accept Case IDs from the Batch class and pass them down to their respective Engines. They exist to satisfy the strict layered architecture.
*   **`ServiceOpsSetupService.cls`**: Handles the complex logic of converting primitive data types into Salesforce Metadata API deployment containers.

### Engines (The Detectors)
*   **`ReplyPulseEngine.cls`**: Queries `EmailMessage` records to determine if the customer sent the last email and the agent hasn't replied yet.
*   **`QueuePulseEngine.cls`**: Checks if a Case is currently owned by a `Group` (Queue) instead of a User, and calculates how long it has been sitting there.
*   **`SLAPulseEngine.cls`**: Queries `CaseMilestone` to find near-breach or breached SLAs, and queries `Case` to find missing `EntitlementId`s.

### Evaluators (The Math)
*   **`ServiceOpsSignalEvaluator.cls`**: Takes raw facts (e.g., "This case has been waiting 45 minutes") and compares them against `ServiceOps_Risk_Rule__mdt` records to determine if that equates to a "Low", "Medium", "High", or "Critical" risk. Returns a staged Signal record.

### Utilities
*   **`ServiceOpsConstants.cls`**: Holds every hardcoded string in the app (Signal Types, Risk Levels, Reason Codes). Prevents typos and makes renaming business concepts globally easy.
*   **`ServiceOpsTestDataFactory.cls`**: Centralized hub for generating mock Cases, Emails, Queues, and Users for test execution.