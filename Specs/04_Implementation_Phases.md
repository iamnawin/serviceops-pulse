# ServiceOps Pulse: Implementation Plan

## Phase 1: Foundation & Proof of Concept (Days 1 - 10)
**Goal:** Prove the technical viability of the ReplyPulse logic and set up the package framework.
1.  Initialize SFDX project (`sfdx force:project:create`).
2.  Define the package namespace.
3.  Deploy custom objects (`ServiceOps_Case_Signal__c`, `ServiceOps_Snapshot__c`).
4.  Deploy Custom Metadata Types.
5.  Build `ReplyPulseEngine.cls` to accurately detect the difference between inbound customer emails and outbound agent emails.
6.  Create a test class with mocked `EmailMessage` records to validate the logic.

## Phase 2: Batch Processing & Dashboards (Days 11 - 30)
**Goal:** Automate the signal generation and visualize it.
1.  Build `ServiceOpsScanBatch.cls` to process open cases in bulk.
2.  Implement `QueuePulseEngine.cls` and integrate it into the batch.
3.  Build the base LWC framework:
    *   `serviceOpsHome`
    *   `replyPulseBoard`
    *   `queuePulseBoard`
4.  Write Apex Controllers (with `cacheable=true`) to supply data to LWCs.

## Phase 3: SLA Pulse, Setup & Polish (Days 31 - 60)
**Goal:** Complete the MVP features and build the Admin setup experience.
1.  Build `SLAPulseEngine.cls` (Querying `CaseMilestone` and `Entitlement`).
2.  Build `serviceOpsSetupWizard` LWC so Admins can easily populate custom metadata settings without using the standard Salesforce setup UI.
3.  Develop the `casePulseDetailPanel` for the Case Record Page.
4.  Implement Permission Sets (`ServiceOps_Admin`, `ServiceOps_User`).

## Phase 4: AppExchange Readiness & Beta (Days 61 - 90)
**Goal:** Prepare for Security Review and Go-To-Market.
1.  Run Checkmarx / Salesforce Code Analyzer (`sfdx scanner:run`).
2.  Fix any CRUD/FLS vulnerabilities in Apex. Ensure `WITH SECURITY_ENFORCED` or `stripInaccessible` is used.
3.  Create AppExchange listing assets (logos, screenshots of the LWC boards, 5-minute demo script).
4.  Deploy to a fresh Sandbox or Dev Org for UAT and beta customer trials.
5.  Submit for Salesforce AppExchange Security Review.