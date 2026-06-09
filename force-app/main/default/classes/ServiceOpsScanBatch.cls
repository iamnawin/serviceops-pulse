/**
 * Class: ServiceOpsScanBatch
 * Purpose: Batch process to scan all open cases for operational risks.
 * Package: ServiceOps Pulse
 * Security: Inherited sharing.
 */
public inherited sharing class ServiceOpsScanBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        ServiceOps_Setting__mdt settings = ServiceOpsSignalService.getSettings();
        Integer windowDays = settings.Scan_Window_Days__c != null ? (Integer)settings.Scan_Window_Days__c : 30;

        // Use dynamic SOQL safely to inject the configurable window
        String query = 'SELECT Id FROM Case WHERE IsClosed = false AND LastModifiedDate >= LAST_N_DAYS:' + windowDays;
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {
        Set<Id> caseIds = new Map<Id, Case>(scope).keySet();

        // 1. Scan Reply Risks
        ReplyPulseService.scanReplyRisks(caseIds);

        // 2. Scan Queue Risks
        QueuePulseService.scanQueueRisks(caseIds);

        // 3. Scan SLA Risks
        SLAPulseService.scanSlaRisks(caseIds);

        // Future Phases: Case Aging, etc.
    }

    public void finish(Database.BatchableContext bc) {
        // Generate a snapshot of current risks at the end of the batch run
        try {
            AggregateResult[] riskCounts = [
                SELECT Signal_Type__c, Risk_Level__c, count(Id) total
                FROM ServiceOps_Case_Signal__c
                WHERE Status__c = :ServiceOpsConstants.SIGNAL_STATUS_OPEN
                WITH USER_MODE
                GROUP BY Signal_Type__c, Risk_Level__c
            ];

            Integer totalWaiting = 0;
            Integer totalQueueStuck = 0;
            Integer totalSlaRisk = 0;
            Integer totalNearBreach = 0;
            Integer totalBreached = 0;
            Integer totalHigh = 0;
            Integer totalCritical = 0;

            for (AggregateResult ar : riskCounts) {
                String type = (String) ar.get('Signal_Type__c');
                String level = (String) ar.get('Risk_Level__c');
                Integer count = (Integer) ar.get('total');

                if (type == ServiceOpsConstants.SIGNAL_TYPE_REPLY) totalWaiting += count;
                if (type == ServiceOpsConstants.SIGNAL_TYPE_QUEUE) totalQueueStuck += count;
                if (type == ServiceOpsConstants.SIGNAL_TYPE_SLA) {
                    totalSlaRisk += count;
                    if (level == ServiceOpsConstants.RISK_LEVEL_CRITICAL) totalBreached += count;
                    else totalNearBreach += count;
                }

                if (level == ServiceOpsConstants.RISK_LEVEL_HIGH) totalHigh += count;
                if (level == ServiceOpsConstants.RISK_LEVEL_CRITICAL) totalCritical += count;
            }

            // Using dynamic SOQL with bind variable for safety and flexibility
            ServiceOps_Setting__mdt settings = ServiceOpsSignalService.getSettings();
            Integer windowDays = settings.Scan_Window_Days__c != null ? (Integer)settings.Scan_Window_Days__c : 30;
            String query = 'SELECT count() FROM Case WHERE IsClosed = false AND LastModifiedDate >= LAST_N_DAYS:' + windowDays;
            Integer openCases = Database.countQuery(query);

            ServiceOps_Snapshot__c snap = new ServiceOps_Snapshot__c(
                Snapshot_Date__c = DateTime.now(),
                Total_Open_Cases__c = openCases,
                Waiting_On_Agent__c = totalWaiting,
                Queue_Stuck_Cases__c = totalQueueStuck,
                SLA_Risk_Cases__c = totalSlaRisk,
                Near_Breach__c = totalNearBreach,
                Breached_Cases__c = totalBreached,
                High_Risk_Cases__c = totalHigh,
                Critical_Risk_Cases__c = totalCritical
            );

            insert as user snap;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to generate ServiceOps Snapshot: ' + e.getMessage());
        }
    }
}
