/**
 * Class: QueuePulseEngine
 * Purpose: Detects if an open case is owned by a queue beyond the configured threshold.
 * Package: ServiceOps Pulse
 * Security: Enforces User Mode for queries.
 */
public inherited sharing class QueuePulseEngine {
    
    /**
     * Processes a list of Case IDs to detect Queue Risk.
     */
    public static void processCases(Set<Id> caseIds) {
        if (caseIds.isEmpty()) return;

        ServiceOps_Setting__mdt settings = ServiceOpsSignalService.getSettings();
        
        // Fetch Cases with Owner info
        // We only care about cases owned by Queues (Group)
        List<ServiceOps_Case_Signal__c> newSignals = new List<ServiceOps_Case_Signal__c>();
        Set<Id> healthyCaseIds = new Set<Id>();

        for (Case c : [
            SELECT Id, OwnerId, CreatedDate, LastModifiedDate
            FROM Case
            WHERE Id IN :caseIds
            WITH USER_MODE
        ]) {
            // Check if Owner is a Queue
            if (String.valueOf(c.OwnerId).startsWith('00G')) {
                // For MVP, Queue Age is based on time since CreatedDate 
                // or we could use LastModifiedDate if we assume it reflects ownership change.
                // Strict rules say: CreatedDate or LastModifiedDate (8.2)
                Long queueAgeMin = (DateTime.now().getTime() - c.CreatedDate.getTime()) / 60000;

                ServiceOps_Case_Signal__c signal = ServiceOpsSignalEvaluator.evaluateRisk(
                    c.Id, 
                    ServiceOpsConstants.SIGNAL_TYPE_QUEUE, 
                    queueAgeMin
                );

                if (signal != null) {
                    signal.Source_Record_Id__c = c.OwnerId;
                    newSignals.add(signal);
                } else {
                    healthyCaseIds.add(c.Id);
                }
            } else {
                // Owned by a User
                healthyCaseIds.add(c.Id);
            }
        }

        ServiceOpsSignalService.upsertSignals(newSignals);
        ServiceOpsSignalService.resolveSignals(healthyCaseIds, ServiceOpsConstants.SIGNAL_TYPE_QUEUE);
    }
}
