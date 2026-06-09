/**
 * Class: ReplyPulseService
 * Purpose: Orchestrates the ReplyPulse logic.
 * Package: ServiceOps Pulse
 * Security: Inherited sharing.
 */
public inherited sharing class ReplyPulseService {
    
    /**
     * Scans and updates Reply Risks for a set of cases.
     */
    public static void scanReplyRisks(Set<Id> caseIds) {
        ReplyPulseEngine.processCases(caseIds);
    }
}
