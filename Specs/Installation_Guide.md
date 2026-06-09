# ServiceOps Pulse: Installation Guide

## 1. Prerequisites
Before installing ServiceOps Pulse, ensure your Salesforce environment meets the following criteria:
*   Salesforce Developer Edition, Sandbox, or Scratch Org.
*   **Entitlements** feature is enabled (Required for SLAPulse).

## 2. Deploying to a Scratch Org
The easiest way to validate the package is by creating a fresh scratch org. The provided configuration file already includes the required Entitlement features.

```bash
# Clone the repository
git clone https://github.com/iamnawin/serviceops-pulse.git
cd serviceops-pulse

# Create the scratch org
sf org create scratch -f config/project-scratch-def.json -a pulse-dev -d 7 --set-default

# Push the source code
sf project deploy start
```

## 3. Assigning Permissions
Once deployed, you must assign the Admin permission set to yourself to view the app and configure it.

```bash
sf org assign permset --name ServiceOps_Admin
```

## 4. Initial Configuration
1.  Navigate to the App Launcher and search for **ServiceOps Pulse**.
2.  Click on the **ServiceOps Setup** tab.
3.  Follow the 3-step wizard to define your Internal Agent Domain (e.g., `yourcompany.com`) and set your operational risk thresholds (Reply SLA, Queue Aging Limit, Near Breach Warning).
4.  Click **Save and Activate**. Note: This uses the Metadata API to deploy changes to Custom Metadata Types, which may take up to 60 seconds to reflect.

## 5. Scheduling the Pulse Scan
The engine relies on a scheduled Apex batch job to detect risks and generate daily snapshots.

Open the **Developer Console** > **Execute Anonymous** and run:
```apex
// Schedules the scan to run at the top of every hour
ServiceOpsScanScheduler.scheduleJob(60);
```

You are now fully installed and ready to track operational health!