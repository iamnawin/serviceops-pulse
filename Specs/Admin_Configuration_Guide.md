# ServiceOps Pulse: Admin Configuration Guide

## 1. Overview
ServiceOps Pulse uses Custom Metadata Types (`.mdt`) to control logic and risk thresholds without requiring code changes. This allows Admins to adapt the tool to their specific business processes.

## 2. Global Settings (`ServiceOps_Setting__mdt`)
These settings control the overarching behavior of the scanning engines. You can modify these via the **ServiceOps Setup** tab (Wizard) or directly in Salesforce Setup.

| Field | Purpose | Example |
| :--- | :--- | :--- |
| **Agent Email Domain** | Helps ReplyPulse differentiate between a customer email and an internal agent reply. | `company.com` |
| **Scan Window (Days)** | Limits the SOQL query to cases modified recently to prevent governor limits in massive orgs. | `30` |
| **Enable Entitlement Risk** | If checked, SLAPulse will flag any open case missing an Entitlement record as a setup risk. | `false` |
| **Closed Status Values** | Comma-separated list of Case Statuses that the engine should ignore. | `Closed, Resolved` |

## 3. Risk Rules (`ServiceOps_Risk_Rule__mdt`)
The Evaluator engine uses these rules to convert raw age metrics (like "Waiting 70 minutes") into distinct Risk Levels.

To customize what constitutes a "High Risk" vs. a "Medium Risk":
1.  Go to **Setup** > **Custom Metadata Types**.
2.  Click **Manage Records** next to **ServiceOps Risk Rule**.
3.  Edit existing rules or create new ones.

### Rule Structure
*   **Signal Type**: Which engine this rule applies to (e.g., `Reply Risk`).
*   **Min Minutes / Max Minutes**: The time bounds for this rule. 
    *   *Example:* Min 30, Max 59 = Medium Risk. Min 60, Max (Blank) = High Risk.
*   **Risk Level**: Low, Medium, High, Critical.
*   **Suggested Action Template**: The text displayed to the Agent on the Case Record Page widget (e.g., "Critical: Reply to this customer immediately.").

## 4. Permission Sets
Assign these based on user roles:
*   **`ServiceOps_Admin`**: Full access to all Custom Objects, Metadata, Apps, and Setup Wizards.
*   **`ServiceOps_Manager`**: View access to the Lightning App, Dashboards, and the ability to manually Resolve/Ignore risk signals.
*   **`ServiceOps_Agent`**: Cannot see the app or dashboards. Only has read access to signals directly related to the Cases they are viewing via the Lightning Record Page widget.