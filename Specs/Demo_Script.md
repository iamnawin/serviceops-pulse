# ServiceOps Pulse: 5-Minute Demo Script

**Target Audience:** Support Managers, VP of Service, Salesforce Admins.

## Scene 1: The Problem (0:00 - 1:00)
*   **Action:** Show a standard Salesforce Case List View or Omni-Channel Supervisor.
*   **Talk Track:** "Service Cloud is great at routing cases and tracking the *First Response*. But what happens after that? What happens when a customer replies on day 3, and the agent is busy? Native Salesforce reporting makes it incredibly hard to track 'Waiting on Agent' time. These are the silent failures that lead to escalations."

## Scene 2: The Command Center (1:00 - 2:30)
*   **Action:** Open the **ServiceOps Pulse** Lightning App. Show the `ServiceOps Pulse Home` dashboard.
*   **Talk Track:** "ServiceOps Pulse is an operations command center that runs in the background. It continuously scans your org for these hidden risks. Right here, we can instantly see we have 5 cases with 'Reply Risk'—meaning the customer replied last and is waiting—and 3 cases stuck in 'Queue Risk'."
*   **Action:** Click the **Reply Risks** tab. Show the datatable.
*   **Talk Track:** "This board prioritizes the bleeding cases. I can see exactly how many minutes this customer has been waiting since their last email, and whether it's crossed into a 'Critical' threshold."

## Scene 3: The Agent Experience (2:30 - 3:30)
*   **Action:** Click into a specific Case record from the datatable. Point to the **ServiceOps Case Pulse** widget on the right sidebar.
*   **Talk Track:** "Agents don't need to hunt for this data. The Pulse widget sits right on the case. It tells the agent exactly what the risk is ('Reply Risk - Critical') and gives them a suggested action based on your company's playbook ('Critical: Reply to this customer immediately'). As soon as the agent sends an email, the engine automatically resolves this signal. No manual clicking required."

## Scene 4: Setup & Simplicity (3:30 - 5:00)
*   **Action:** Click the **ServiceOps Setup** tab. Show the Wizard.
*   **Talk Track:** "Unlike massive enterprise tools, ServiceOps Pulse takes 3 minutes to deploy. It's 100% native. The Admin just enters their email domain and sets the SLA thresholds in this wizard. The app handles the rest."
*   **Action:** (Optional) Show a Salesforce Report based on `ServiceOps_Snapshot__c`.
*   **Talk Track:** "And because we take a daily snapshot of these risks, your leadership team can finally report on operational health trends over time. ServiceOps Pulse stops escalations before they happen."