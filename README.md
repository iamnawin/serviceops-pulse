# ServiceOps Pulse - Developer Setup Guide

This guide explains how to clone the repository, deploy the code to a Salesforce environment, and test the core functionality.

## Prerequisites
1.  **Salesforce CLI (`sf`)**: [Install here](https://developer.salesforce.com/tools/salesforcecli)
2.  **A Salesforce Developer Edition or Scratch Org**
3.  **Git**

---

## 1. Clone the Repository
```bash
git clone https://github.com/iamnawin/serviceops-pulse.git
cd serviceops-pulse
```

## 2. Authenticate and Deploy
If you are using a **Developer Edition/Sandbox**:
```bash
# Login to your org
sf org login web -a dev-org

# Deploy the metadata
sf project deploy start --target-org dev-org
```

If you are using a **Scratch Org**:
```bash
# Create a scratch org
sf org create scratch -f config/project-scratch-def.json -a pulse-scratch -d 7

# Push the metadata
sf project deploy start
```

## 3. Assign Permissions
Assign the ServiceOps Admin permission set to your user:
```bash
sf org assign permset --name ServiceOps_Admin --target-org dev-org
```

## 4. Run Apex Tests
Verify the logic is working correctly by running all tests:
```bash
sf apex test run --wait 10 --result-format human --target-org dev-org
```

---

## 5. Manual Testing (The "Pulse" Walkthrough)

### Step A: Configure Risk Rules
Since the app uses Custom Metadata, you need to ensure rules exist.
1. In Salesforce, go to **Setup** > **Custom Metadata Types**.
2. Click **Manage Records** next to **ServiceOps Risk Rule**.
3. Create a rule for **Reply Risk**:
   - Label: `Reply Risk 30 Min`
   - Signal Type: `Reply Risk`
   - Min Minutes: `30`
   - Risk Level: `High`
   - Reason Code: `REPLY_WAITING_ON_AGENT`
4. Create a rule for **Queue Risk**:
   - Label: `Queue Risk 60 Min`
   - Signal Type: `Queue Risk`
   - Min Minutes: `60`
   - Risk Level: `High`
   - Reason Code: `QUEUE_OWNERSHIP_STUCK`

### Step B: Trigger a Reply Risk
1. Create a new **Case**.
2. Create an **EmailMessage** related to that Case:
   - Status: `Received`
   - Incoming: `True`
   - Message Date: Set it to `1 hour ago`.
3. Run the scan manually in **Developer Console** > **Execute Anonymous**:
   ```apex
   Database.executeBatch(new ServiceOpsScanBatch());
   ```
4. Check the **ServiceOps Case Signals** tab. You should see a new "Reply Risk" signal record.

### Step C: Trigger a Queue Risk
1. Create a new **Case**.
2. Change the **Owner** of the Case to a **Queue**.
3. Ensure the Case's `CreatedDate` is older than your configured metadata threshold.
4. Run the scan again. You should see a "Queue Risk" signal record.

### Step D: View the Dashboard
1. Go to **Lightning App Builder**.
2. Create a new **App Page** or edit the **Home Page**.
3. Drag the **ServiceOps Pulse Home**, **Reply Pulse Board**, and **Queue Pulse Board** components onto the page.
4. Save and Activate. You will now see the operational risks visualized.
