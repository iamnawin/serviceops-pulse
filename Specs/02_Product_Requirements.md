# ServiceOps Pulse: Product Requirements Document (PRD)

## 1. Product Overview
**ServiceOps Pulse** is a Salesforce-native operations intelligence application for Service Cloud. It detects "silent failures" in support operations before they escalate, providing actionable insights for Support Managers and Admins.

## 2. Target Audience
*   **Support Managers / Team Leads:** Need visibility into queue health, unanswered customer replies, and near-breach SLAs.
*   **Salesforce Admins:** Need visibility into configuration health (SetupPulse) and a simple setup experience.
*   **Support Agents:** Need clear direction on the most critical cases that are silently aging.

## 3. Core Modules (MVP)
### 3.1 ReplyPulse (Email-to-Case Intelligence)
*   Tracks time since the last inbound customer email.
*   Compares inbound time to the latest outbound agent email.
*   Flags cases as "Waiting on Agent" if customer replied last.
*   Calculates Next Response SLA risk based on business hours.

### 3.2 QueuePulse (Queue Risk Monitor)
*   Detects open cases owned by Queues.
*   Calculates "Queue Age" (time since ownership change).
*   Highlights the oldest unassigned cases per queue.
*   Warns if a queue exceeds capacity or aging thresholds.

### 3.3 SLAPulse (Milestone Visibility)
*   Identifies cases near active milestone breaches.
*   Highlights cases that *should* have an entitlement based on Priority but do not.
*   Cross-references with customer reply data to ensure SLAs are advancing.

## 4. Extended Modules (Fast Follows)
*   **CasePulse:** Detects "No Touch" cases, ping-pong cases (too many status changes), and high reopen rates.
*   **SetupPulse:** Scans org configuration for empty queues, invalid Org-Wide Email Addresses, and inactive Entitlement processes.
*   **KnowledgePulse:** Highlights cases solved without articles or articles shared but not published publicly.

## 5. User Stories
*   *As a Support Manager, I want to see a dashboard of cases where the customer replied over 4 hours ago, so I can assign someone to respond.*
*   *As a Support Manager, I want to see the oldest case sitting in the Tier 2 Support Queue, so I can rebalance the workload.*
*   *As an Admin, I want to configure risk thresholds using custom metadata so I don't have to write code to change SLA warning times.*
*   *As a Support Agent, I want to see a clear explanation on the Case record of why it has been flagged as "High Risk."*