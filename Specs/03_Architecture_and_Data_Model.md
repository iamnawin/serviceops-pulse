# ServiceOps Pulse: Architecture and Data Model

## 1. Overview
The application will be built as a managed package using standard Salesforce development paradigms: Custom Objects for transactional data, Custom Metadata for configuration, Apex for the processing engine, and LWC for the UI. No external integrations (AWS/Heroku) are required for the MVP.

## 2. Data Model
### Standard Objects (Read Only)
*   `Case`
*   `EmailMessage`
*   `CaseMilestone`
*   `Entitlement`
*   `Group` / `GroupMember` (Queues)

### Custom Objects
*   **`ServiceOps_Case_Signal__c`**
    *   `Case__c` (Lookup to Case)
    *   `Signal_Type__c` (Picklist: Reply Risk, Queue Risk, SLA Risk)
    *   `Risk_Level__c` (Picklist: Low, Medium, High, Critical)
    *   `Status__c` (Picklist: Open, Resolved, Ignored)
    *   `Time_Since_Customer_Reply_Min__c` (Number)
    *   `Queue_Age_Min__c` (Number)
    *   `Suggested_Action__c` (Long Text)
*   **`ServiceOps_Snapshot__c`**
    *   Used for weekly/daily trend reporting.
    *   `Snapshot_Date__c` (DateTime)
    *   `Waiting_On_Agent__c` (Number)
    *   `Near_Breach__c` (Number)

### Custom Metadata Types
*   **`ServiceOps_Setting__mdt`**
    *   Global package settings.
    *   `Reply_SLA_Hours__c`, `Queue_Aging_Threshold_Hours__c`, `Agent_Email_Domain__c`.
*   **`ServiceOps_Risk_Rule__mdt`**
    *   Defines dynamic thresholds for calculating `Risk_Level__c`.

## 3. Apex Layer (The Engine)
*   **Schedulable / Batch Architecture:**
    *   `ServiceOpsScanScheduler.cls`: Runs every X minutes or hourly.
    *   `ServiceOpsScanBatch.cls`: Queries open cases and delegates to engines.
*   **Processing Engines:**
    *   `ReplyPulseEngine.cls`: Processes Case + EmailMessage.
    *   `QueuePulseEngine.cls`: Processes Case + Group.
    *   `SLAPulseEngine.cls`: Processes Case + CaseMilestone.
*   **Services:**
    *   `ServiceOpsSignalService.cls`: Handles DML for `ServiceOps_Case_Signal__c` records.

## 4. LWC UI Layer (The Command Center)
*   `serviceOpsHome`: Executive dashboard with summary metric cards.
*   `replyPulseBoard`: Datatable view of Reply signals with quick actions.
*   `queuePulseBoard`: Kanban or Card view grouping cases by Queue.
*   `serviceOpsSetupWizard`: Stepper component to guide Admins through creating `ServiceOps_Setting__mdt` records.
*   `casePulseDetailPanel`: LWC to be placed on the standard Case Lightning Record Page showing the current risk status.