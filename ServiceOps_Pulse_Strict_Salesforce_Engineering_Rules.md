# ServiceOps Pulse — Strict Salesforce Engineering Rules

**Purpose:** This file is the non-negotiable engineering rulebook for building ServiceOps Pulse as a Salesforce-native AppExchange-ready product using Apex, LWC, Custom Objects, Custom Metadata, Permission Sets, and Salesforce standard objects only.

**Primary goal:** Keep the code simple, testable, secure, package-safe, and easy to manage. Target **95% Apex test coverage**, but never chase coverage by writing fake tests that do not assert behavior.

---

## 1. Build Boundary Rules

### 1.1 Native-only MVP
ServiceOps Pulse MVP must be built with:
- Apex classes
- Apex batch / schedulable / queueable where required
- Lightning Web Components
- Custom Objects
- Custom Metadata Types
- Permission Sets
- Salesforce standard objects: Case, EmailMessage, CaseMilestone, Entitlement, Group, GroupMember

### 1.2 Strictly not allowed in Phase 1–4
Do not use:
- External Node / Java / Python backend
- Heroku / AWS / Azure / GCP runtime
- External database
- External AI API
- Chrome extension dependency
- Slack / Teams integration
- Hardcoded org-specific IDs
- Direct unmanaged-org assumptions
- Complex frameworks that make package review harder

### 1.3 Package-first mindset
Every class, field, object, LWC, permission, label, and custom metadata record must be designed as if it will go into a managed package.

---

## 2. Architecture Rules

### 2.1 Required architecture layers
Use this structure strictly:

```text
LWC UI Layer
  -> Apex Controller Layer
      -> Service Layer
          -> Engine Layer
              -> Evaluator Layer
                  -> Signal DML Layer
```

### 2.2 Layer responsibilities

| Layer | Responsibility | Not Allowed |
|---|---|---|
| LWC | Display data, call Apex, simple validation | Business logic, SOQL, complex risk calculations |
| Apex Controller | Expose safe methods to LWC | Heavy processing, direct unmanaged DML without service |
| Service Layer | Orchestration and transaction control | UI formatting logic |
| Engine Layer | Detect raw facts from Case/Email/Queue/SLA | Deciding final risk label directly |
| Evaluator Layer | Convert facts into Risk Level, Reason, Suggested Action | SOQL-heavy logic |
| Signal Service | Insert/update/resolve signal records | Business-specific detection logic |

### 2.3 Required class pattern
Every feature must follow this pattern:

```text
ReplyPulseController.cls
ReplyPulseService.cls
ReplyPulseEngine.cls
ServiceOpsSignalEvaluator.cls
ServiceOpsSignalService.cls
ReplyPulseEngineTest.cls
ServiceOpsTestDataFactory.cls
```

---

## 3. Naming Rules

### 3.1 Class naming
Use clear names. No clever names.

Allowed:
- `ReplyPulseEngine`
- `QueuePulseEngine`
- `SLAPulseEngine`
- `ServiceOpsSignalService`
- `ServiceOpsSignalEvaluator`
- `ServiceOpsScanBatch`
- `ServiceOpsScanScheduler`
- `ServiceOpsDashboardController`

Not allowed:
- `Helper1`
- `CommonUtil2`
- `ManagerClass`
- `ProcessorFinal`
- `NewService`

### 3.2 Field naming
All package custom fields must be explicit and admin-readable.

Example:
- `Last_Inbound_Email_Date__c`
- `Last_Outbound_Email_Date__c`
- `Time_Since_Customer_Reply_Min__c`
- `Reason_Code__c`
- `Reason_Text__c`
- `Suggested_Action__c`

Avoid vague fields:
- `Value__c`
- `Status2__c`
- `Flag__c`
- `Data__c`

### 3.3 Picklist values
Picklist values must be stable and integration-safe. Use business-readable labels, not random abbreviations.

Example:
```text
Signal_Type__c:
- Reply Risk
- Queue Risk
- SLA Risk
- Case Aging Risk
- Knowledge Risk
- Setup Risk
- Escalation Risk
```

---

## 4. Object and Field Rules

### 4.1 Required custom object: `ServiceOps_Case_Signal__c`
Minimum fields:

| Field API Name | Type | Required Use |
|---|---|---|
| `Case__c` | Lookup(Case) | Related case |
| `Signal_Type__c` | Picklist | Reply Risk, Queue Risk, SLA Risk, etc. |
| `Risk_Level__c` | Picklist | Low, Medium, High, Critical |
| `Status__c` | Picklist | Open, Resolved, Ignored |
| `Reason_Code__c` | Text | Machine-readable reason |
| `Reason_Text__c` | Long Text | Human-readable explanation |
| `Suggested_Action__c` | Long Text | What manager/agent should do |
| `Last_Inbound_Email_Date__c` | DateTime | Last customer email |
| `Last_Outbound_Email_Date__c` | DateTime | Last agent email |
| `Time_Since_Customer_Reply_Min__c` | Number | Reply age |
| `Queue_Age_Min__c` | Number | Queue age |
| `Milestone_Target_Date__c` | DateTime | Active milestone target |
| `Minutes_To_Breach__c` | Number | SLA risk number |
| `Source_Record_Id__c` | Text(18) | EmailMessage/CaseMilestone/source Id |
| `Detected_At__c` | DateTime | Signal detected time |
| `Resolved_At__c` | DateTime | Signal resolved time |
| `Ignored_Reason__c` | Long Text | Why user ignored it |

### 4.2 Required custom object: `ServiceOps_Snapshot__c`
Minimum fields:
- `Snapshot_Date__c`
- `Total_Open_Cases__c`
- `Waiting_On_Agent__c`
- `Near_Breach__c`
- `Breached_Cases__c`
- `Queue_Stuck_Cases__c`
- `High_Risk_Cases__c`
- `Critical_Risk_Cases__c`
- `Average_Reply_Age_Min__c`

### 4.3 Required custom metadata: `ServiceOps_Setting__mdt`
Minimum fields:
- `Is_Active__c`
- `Reply_SLA_Hours__c`
- `Queue_Aging_Threshold_Hours__c`
- `No_Touch_Threshold_Hours__c`
- `Near_Breach_Threshold_Minutes__c`
- `Agent_Email_Domain__c`
- `Closed_Status_Values__c`
- `Reply_Time_Calculation_Mode__c`
- `Default_Business_Hours_Id__c`
- `Scan_Frequency_Minutes__c`

### 4.4 Required custom metadata: `ServiceOps_Risk_Rule__mdt`
Minimum fields:
- `Signal_Type__c`
- `Risk_Level__c`
- `Min_Minutes__c`
- `Max_Minutes__c`
- `Priority__c`
- `Is_Active__c`
- `Reason_Code__c`
- `Suggested_Action_Template__c`

---

## 5. Apex Security Rules

### 5.1 Sharing declaration required
Every Apex class must explicitly declare sharing.

Allowed:
```apex
public with sharing class ReplyPulseController { }
public inherited sharing class ReplyPulseService { }
```

Not allowed:
```apex
public class ReplyPulseController { }
```

### 5.2 CRUD/FLS enforcement required
Every Apex read/write path that touches Salesforce records must enforce object and field security.

Required options:
- Prefer Lightning Data Service for simple record UI when possible.
- Use `WITH SECURITY_ENFORCED` or `WITH USER_MODE` for safe SOQL where suitable.
- Use `Security.stripInaccessible()` before DML or when dynamic fields are involved.
- For DML, verify object create/update/delete permission before writing.

### 5.3 No unsafe dynamic SOQL
Dynamic SOQL is allowed only when required and must use bind variables or whitelisted field names.

Not allowed:
```apex
String q = 'SELECT Id FROM Case WHERE Subject LIKE \'%' + userInput + '%\'';
```

Allowed:
```apex
String searchTerm = '%' + String.escapeSingleQuotes(userInput) + '%';
List<Case> cases = [SELECT Id FROM Case WHERE Subject LIKE :searchTerm];
```

### 5.4 No hardcoded IDs
Never hardcode:
- Record Type Id
- Queue Id
- Profile Id
- Permission Set Id
- Business Hours Id
- Org-Wide Email Address Id
- User Id

Use DeveloperName, API name, Custom Metadata, Custom Settings, or setup wizard configuration.

### 5.5 No empty catch blocks
Every catch block must do one of:
- Throw a handled exception
- Log a package-safe error record
- Return a controlled error response

Not allowed:
```apex
catch (Exception e) { }
```

### 5.6 Bulkification required
All Apex must support bulk records.

Rules:
- No SOQL inside loops
- No DML inside loops
- No callouts inside loops
- Use maps and sets
- Batch must use scope-safe processing
- Tests must include multiple records, not only one happy-path record

### 5.7 Governor limit protection
Every engine must be designed for large orgs.

Rules:
- Query only required fields
- Filter open cases only
- Use batch scope size intentionally
- Avoid querying all EmailMessage records at once
- Use `Map<Id, List<EmailMessage>>` for grouping
- Avoid recursive processing

---

## 6. Apex Code Simplicity Rules

### 6.1 Method size
Target method length: under 40 lines.
If a method crosses 60 lines, refactor it.

### 6.2 Class size
Target class size: under 300 lines.
If a class crosses 400 lines, split it.

### 6.3 One responsibility per class
No god classes.

Bad:
```text
ServiceOpsEverythingManager
```

Good:
```text
ReplyPulseEngine
QueuePulseEngine
SLAPulseEngine
ServiceOpsSignalService
```

### 6.4 Constants
All repeated strings must be constants.

Allowed:
```apex
public static final String SIGNAL_REPLY_RISK = 'Reply Risk';
```

Not allowed:
```apex
signal.Signal_Type__c = 'Reply Risk'; // repeated everywhere
```

### 6.5 No clever code
Readable code wins. If a junior Salesforce dev cannot understand it in 10 minutes, it is too clever.

---

## 7. ReplyPulse Logic Rules

### 7.1 Reply detection definition
A case is **Waiting on Agent** when:
- Case is open, and
- The latest relevant EmailMessage on the case is inbound from customer, and
- There is no later outbound EmailMessage from an internal agent, and
- The case is not in an ignored/closed status.

### 7.2 EmailMessage fields to use
Use available standard fields such as:
- `ParentId`
- `Incoming`
- `MessageDate`
- `CreatedDate`
- `FromAddress`
- `ToAddress`
- `Status`

### 7.3 Internal vs customer detection
MVP detection must use:
- `EmailMessage.Incoming = true` for customer inbound
- `EmailMessage.Incoming = false` for agent outbound
- Optional `Agent_Email_Domain__c` for additional filtering

Do not overcomplicate with NLP or AI.

### 7.4 Reply SLA calculation
MVP starts with Calendar Hours unless Business Hours mode is explicitly configured.

---

## 8. QueuePulse Logic Rules

### 8.1 Queue risk definition
A case is Queue Risk when:
- Case is open, and
- OwnerId belongs to a Queue, and
- Case has been queue-owned beyond configured threshold.

### 8.2 MVP queue fields
Use:
- `Case.OwnerId`
- `Case.CreatedDate`
- `Case.LastModifiedDate`
- `Group.Type = 'Queue'`
- `Group.Name`

### 8.3 Future capacity logic
Do not build capacity prediction in MVP. It requires more assumptions and may become inaccurate without Omni-Channel availability data.

---

## 9. SLAPulse Logic Rules

### 9.1 SLA visibility first
MVP SLAPulse must focus on visibility:
- Active milestones
- Near breach
- Breached cases
- Missing entitlement where required

Do not attempt to replace Salesforce Entitlements.

### 9.2 Required caution
Entitlement and milestone logic varies by org. Keep rules configurable through Custom Metadata.

---

## 10. LWC Rules

### 10.1 LWC responsibilities
LWC should:
- Display risk cards
- Show datatables
- Call Apex controllers
- Provide filters
- Show clear reason/suggested action

LWC should not:
- Calculate core risk logic
- Hardcode business thresholds
- Query Salesforce data directly
- Store hidden business rules in JavaScript

### 10.2 Base components first
Use Salesforce base Lightning components wherever possible:
- `lightning-datatable`
- `lightning-card`
- `lightning-combobox`
- `lightning-button`
- `lightning-badge`
- `lightning-progress-indicator`

### 10.3 UI clarity rule
Every signal card must answer:
```text
What is wrong?
Why is it risky?
How long has it been risky?
What should the user do next?
```

### 10.4 No heavy UI frameworks
Do not add third-party JS/CSS libraries in MVP unless absolutely required.

---

## 11. Test Class Rules — 95% Target

### 11.1 Coverage target
Minimum deployable target: 85%.
Internal quality target: **95%**.

Coverage must come from meaningful tests with assertions.

### 11.2 Test structure
Every test class must use:
```apex
@TestSetup
static void setupData() { }
```

Where appropriate, use:
```apex
Test.startTest();
// execute logic
Test.stopTest();
```

### 11.3 Required test factory
All common test data must come from:
```text
ServiceOpsTestDataFactory.cls
```

Factory must create:
- Users
- Accounts
- Contacts
- Cases
- EmailMessages
- Entitlements if needed
- CaseMilestones if possible/needed
- Queues/Groups where possible
- ServiceOps settings

### 11.4 Required ReplyPulse tests
Must test:
- Customer replied last -> creates High/Medium Reply Risk signal
- Agent replied last -> no open Reply Risk signal
- No emails -> no Reply Risk signal
- Only inbound email -> creates signal
- Only outbound email -> no waiting-on-agent signal
- Multiple inbound/outbound emails -> uses latest email correctly
- Closed case -> ignored
- Existing open signal -> updated, not duplicated
- Resolved signal -> marked Resolved when agent replies
- Bulk cases -> no SOQL/DML loop issue

### 11.5 Required QueuePulse tests
Must test:
- Open case owned by queue beyond threshold -> Queue Risk
- Case owned by user -> no Queue Risk
- Closed queue-owned case -> ignored
- Multiple queues -> grouped correctly
- Existing queue signal -> updated not duplicated

### 11.6 Required SLAPulse tests
Must test:
- Active milestone near breach -> SLA Risk
- Breached milestone -> High/Critical risk
- No entitlement when expected -> missing entitlement signal
- Closed case -> ignored

### 11.7 Assertion rules
Every test must assert:
- Number of signals created/updated
- Risk level
- Reason code
- Suggested action not blank
- Related Case Id
- No duplicate open signal for same Case + Signal Type

### 11.8 No SeeAllData
Strictly not allowed:
```apex
@IsTest(SeeAllData=true)
```

Only exception: if Salesforce platform limitation makes a setup object impossible to create in test context. Any exception must be documented in the class header.

---

## 12. Error Handling and Logging Rules

### 12.1 Controlled errors only
LWC controllers must not expose raw stack traces.

Allowed:
```text
Unable to load ServiceOps signals. Please contact your Salesforce admin.
```

Not allowed:
```text
System.NullPointerException: Attempt to de-reference a null object at line 47
```

### 12.2 Error object optional
If logging is added, use:
```text
ServiceOps_Error_Log__c
```

Fields:
- `Class_Name__c`
- `Method_Name__c`
- `Message__c`
- `Record_Id__c`
- `Severity__c`
- `Logged_At__c`

Keep this optional for MVP if it delays Phase 1.

---

## 13. Performance Rules

### 13.1 Batch scanning
Use scheduled/batch Apex for scans. Do not scan all cases live from LWC.

### 13.2 Query filters
Default query should filter:
- Open cases only
- Recently modified cases where possible
- EmailMessages related to selected case scope only

### 13.3 Avoid duplicate signals
There must be only one open signal per:
```text
Case + Signal Type + Reason Code
```

If the same risk remains, update the existing signal. Do not insert duplicates.

---

## 14. Permission and Access Rules

### 14.1 Required permission sets
Create:
- `ServiceOps_Admin`
- `ServiceOps_Manager`
- `ServiceOps_Agent`

### 14.2 Access model
- Admin: setup wizard, settings, all dashboards
- Manager: dashboards, case risk boards, ignore/resolve actions
- Agent: case detail panel and assigned case signals

### 14.3 No profile dependency
Never design features around a specific Profile name.

---

## 15. AppExchange/Security Review Rules

### 15.1 Static analysis required
Run Salesforce Code Analyzer before every milestone.

Minimum checks:
- Apex security rules
- PMD Apex rules
- LWC JavaScript rules
- Graph Engine where applicable

### 15.2 Security review blockers to avoid
Strictly avoid:
- Missing CRUD/FLS checks
- Unsafe dynamic SOQL
- Stored XSS in LWC
- Hardcoded secrets
- Debug logs with sensitive data
- Exposed stack traces
- Insecure remote site/callout assumptions
- Over-permissive permission sets

### 15.3 Debug rules
No permanent debug statements with customer data.

Not allowed:
```apex
System.debug(email.Body);
```

Allowed only temporarily during local development and removed before commit.

---

## 16. Documentation Rules

### 16.1 Every class must have header comment
Required:
```apex
/**
 * Class: ReplyPulseEngine
 * Purpose: Detects whether an open case is waiting on agent reply.
 * Package: ServiceOps Pulse
 * Security: Does not perform DML. Caller must pass security-filtered records.
 */
```

### 16.2 Every public method must explain
- Input
- Output
- Side effects
- Security expectation

### 16.3 Admin documentation required
For each feature, document:
- What it does
- What settings control it
- What records it creates
- How to disable it
- Known limitations

---

## 17. Git and Delivery Rules

### 17.1 Branching
Use simple branches:
```text
main
feat/phase1-foundation-replypulse
feat/phase2-dashboard-queuepulse
fix/security-crud-fls
```

### 17.2 Commit rule
Every commit must be small and explain the reason.

Good:
```text
Add ReplyPulse engine to detect unanswered inbound customer emails
```

Bad:
```text
updates
```

### 17.3 Pull request checklist
Before merge:
- Apex tests pass
- Coverage target met
- Code Analyzer run
- CRUD/FLS reviewed
- No hardcoded IDs
- No debug logs with customer data
- LWC loads without console errors
- Documentation updated

---

## 18. Phase Control Rules

### Phase 1 allowed
- SFDX structure
- Core objects/metadata
- ReplyPulse engine
- Signal evaluator
- Signal service
- Test factory
- Apex tests

### Phase 1 not allowed
- Complex dashboards
- Queue capacity prediction
- KnowledgePulse
- SetupPulse
- Slack/Teams
- Agentforce
- External APIs

### Phase 2 allowed
- Batch scan
- QueuePulse MVP
- Basic dashboards
- Cacheable Apex controllers

### Phase 3 allowed
- SLAPulse
- Setup wizard
- Case detail panel
- Permission sets

### Phase 4 allowed
- Security review readiness
- Code Analyzer cleanup
- Beta packaging
- AppExchange listing assets

---

## 19. Definition of Done

A story is not done unless:
- It works in a scratch org/dev org
- Apex tests pass
- Relevant test assertions exist
- No duplicate signal issue
- CRUD/FLS/security review pattern applied
- LWC has loading/error/empty states
- Admin can understand the result
- Code is readable
- Documentation updated

---

## 20. Golden Rule

Do not build a clever monster.

Build a clean Salesforce-native package that an admin can install, understand, configure, and trust.

The product should feel like:
```text
Install -> Configure -> Scan -> See Risk -> Take Action
```

Not like:
```text
Install -> Debug -> Ask Developer -> Open 12 Setup Pages -> Cry
```

## 21  Rule

Use managed package for AppExchange.
Keep core logic in protected Apex.
Keep customer settings configurable but not exposing algorithms.
Avoid global classes unless building official extension APIs.
Do not store secret logic in visible LWC JavaScript.
Do not rely on customer-editable Flow for core logic.

All ServiceOps Pulse package-owned metadata must use normal source names in the SFDX project.
Do not manually prefix package-owned components with namespace in source unless Salesforce packaging specifically requires it.

All subscriber/customer-specific fields must be configurable through Custom Metadata and validated using Schema Describe before query or DML.

The package must not depend on any subscriber namespace or third-party managed package namespace for MVP.

All dynamic SOQL must use validated object and field names only.

All LWC components must receive safe DTO/wrapper data from Apex instead of directly handling subscriber-specific field logic.
