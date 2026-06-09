/**
 * Class: ServiceOpsConstants
 * Purpose: Central repository for package constants.
 * Package: ServiceOps Pulse
 * Security: None (Constants only)
 */
public inherited sharing class ServiceOpsConstants {
    // Signal Types
    public static final String SIGNAL_TYPE_REPLY = 'Reply Risk';
    public static final String SIGNAL_TYPE_QUEUE = 'Queue Risk';
    public static final String SIGNAL_TYPE_SLA = 'SLA Risk';
    public static final String SIGNAL_TYPE_CASE_AGING = 'Case Aging Risk';

    // Risk Levels
    public static final String RISK_LEVEL_LOW = 'Low';
    public static final String RISK_LEVEL_MEDIUM = 'Medium';
    public static final String RISK_LEVEL_HIGH = 'High';
    public static final String RISK_LEVEL_CRITICAL = 'Critical';

    // Signal Statuses
    public static final String SIGNAL_STATUS_OPEN = 'Open';
    public static final String SIGNAL_STATUS_RESOLVED = 'Resolved';
    public static final String SIGNAL_STATUS_IGNORED = 'Ignored';

    // Reason Codes
    public static final String REASON_REPLY_WAITING = 'REPLY_WAITING_ON_AGENT';
    public static final String REASON_QUEUE_STUCK = 'QUEUE_OWNERSHIP_STUCK';
    public static final String REASON_SLA_NEAR_BREACH = 'SLA_NEAR_BREACH';
    public static final String REASON_SLA_BREACHED = 'SLA_BREACHED';
}
