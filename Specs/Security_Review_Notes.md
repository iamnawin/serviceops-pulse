# ServiceOps Pulse: Security Review Notes

This document provides a summary of the security practices implemented in the ServiceOps Pulse codebase, intended to assist reviewers during the Salesforce AppExchange Security Review process.

## 1. Data Access & Sharing (CRUD/FLS)
*   **User Mode Enforcement:** All database operations (SOQL and DML) strictly utilize the `WITH USER_MODE` or `as user` keywords. 
    *   *See:* `ServiceOpsSignalService.cls` for centralized DML handling.
*   **Class Sharing:** All classes handling business logic or exposing `@AuraEnabled` methods declare `inherited sharing` to respect the caller's context.

## 2. Dynamic SOQL & Injection Prevention
*   Dynamic SOQL is utilized sparingly. Where necessary (e.g., the batch query locator window), inputs are cast to integers (`Integer windowDays`) before concatenation, preventing any possibility of SOQL injection.

## 3. Cross-Site Scripting (XSS)
*   The UI relies entirely on standard Lightning Web Components (LWC).
*   No third-party UI frameworks, unescaped `innerHTML`, or raw DOM manipulation are used.
*   No external stylesheets or scripts are loaded.

## 4. Metadata API Usage
*   The application uses `Metadata.Operations.enqueueDeployment` to allow Admins to easily configure settings via a Setup Wizard.
*   This functionality is strictly gated behind the `ServiceOps_Admin` permission set and requires the user to have native "Customize Application" privileges to succeed.

## 5. Governor Limit Protections (Bulkification)
*   **No SOQL/DML in Loops:** All engines (ReplyPulse, QueuePulse, SLAPulse) are heavily bulkified, utilizing Sets and Maps to aggregate queries.
*   **Enterprise Scalability:** The `ServiceOpsScanBatch` query is bounded by a configurable `Scan_Window_Days__c` setting (default 30 days) to prevent hitting the 50,000 SOQL row limit in orgs with millions of ancient cases.

## 6. External Callouts
*   **None.** The application is 100% native to the Salesforce platform. No data is transmitted to external servers (AWS, Heroku, etc.).

## 7. Code Analyzer Verification
*   The codebase is continuously checked against the Salesforce Code Analyzer (`sfdx scanner:run --engine "pmd,eslint,eslint-lwc"`).
*   **Zero** security violations (CRUD/FLS, Injection, CSRF, strict async/await rules) currently exist. All remaining warnings are minor PMD styling suggestions (e.g., missing ApexDocs on test methods, or camelCase warnings triggered by standard Salesforce API naming conventions).