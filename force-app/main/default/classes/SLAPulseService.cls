/**
 * Class: SLAPulseService
 * Purpose: Orchestrates the SLAPulse logic.
 * Package: ServiceOps Pulse
 * Security: Inherited sharing.
 */
public inherited sharing class SLAPulseService {
    
    /**
     * Scans and updates SLA Risks for a set of cases.
     */
    public static void scanSlaRisks(Set<Id> caseIds) {
        SLAPulseEngine.processCases(caseIds);
    }
}
