/**
 * Class: QueuePulseService
 * Purpose: Orchestrates the QueuePulse logic.
 * Package: ServiceOps Pulse
 * Security: Inherited sharing.
 */
public inherited sharing class QueuePulseService {
    
    /**
     * Scans and updates Queue Risks for a set of cases.
     */
    public static void scanQueueRisks(Set<Id> caseIds) {
        QueuePulseEngine.processCases(caseIds);
    }
}
