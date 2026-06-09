/**
 * Class: SLAPulseEngine
 * Purpose: Detects SLA risks such as near-breach milestones and missing entitlements.
 * Package: ServiceOps Pulse
 * Security: Enforces User Mode for queries.
 */
public inherited sharing class SLAPulseEngine {
    
    /**
     * Processes a list of Case IDs to detect SLA Risk.
     */
    public static void processCases(Set<Id> caseIds) {
        if (caseIds.isEmpty()) return;

        ServiceOps_Setting__mdt settings = ServiceOpsSignalService.getSettings();
        
        List<ServiceOps_Case_Signal__c> newSignals = new List<ServiceOps_Case_Signal__c>();
        Set<Id> healthyCaseIds = new Set<Id>();

        // 1. Identify cases missing entitlements when expected
        // For MVP, "expected" could mean any non-closed case, but we'll focus on those without EntitlementId
        // This is a setup risk/SLA blind spot.
        if (settings.Enable_Entitlement_Risk__c == true) {
            for (Case c : [
                SELECT Id, EntitlementId, Priority
                FROM Case
                WHERE Id IN :caseIds AND EntitlementId = null
                WITH USER_MODE
            ]) {
                ServiceOps_Case_Signal__c signal = ServiceOpsSignalEvaluator.evaluateRisk(
                    c.Id, 
                    ServiceOpsConstants.SIGNAL_TYPE_SLA, 
                    0 
                );

                if (signal != null) {
                    signal.Reason_Code__c = 'MISSING_ENTITLEMENT';
                    signal.Reason_Text__c = 'Case has no active entitlement process. SLA tracking is disabled.';
                    newSignals.add(signal);
                }
            }
        }

        // 2. Identify cases near breach or already breached using CaseMilestone
        // We look for active milestones that are not completed.
        for (CaseMilestone cm : [
            SELECT CaseId, MilestoneTypeId, TargetDate, IsViolated, IsCompleted, TargetResponseInMins
            FROM CaseMilestone
            WHERE CaseId IN :caseIds AND IsCompleted = false
            WITH USER_MODE
        ]) {
            Long minutesToBreach = (cm.TargetDate.getTime() - DateTime.now().getTime()) / 60000;
            
            // If already violated, we treat it as a critical/high risk with "negative" minutes to breach
            // For the evaluator, we'll pass minutes to breach logic. 
            // However, the current evaluator expects "age". For SLA, "risk" increases as "minutes to breach" decreases.
            // We'll normalize this: Risk Age = (Constant Threshold - minutesToBreach).
            // Or better: update evaluator to handle SLA specifically. 
            // For MVP: if violated, set high risk. If near, set risk.
            
            String riskLevel = null;
            if (cm.IsViolated) {
                riskLevel = ServiceOpsConstants.RISK_LEVEL_CRITICAL;
            } else if (minutesToBreach <= (settings.Near_Breach_Threshold_Minutes__c != null ? settings.Near_Breach_Threshold_Minutes__c : 30)) {
                riskLevel = ServiceOpsConstants.RISK_LEVEL_HIGH;
            }

            if (riskLevel != null) {
                ServiceOps_Case_Signal__c signal = new ServiceOps_Case_Signal__c();
                signal.Case__c = cm.CaseId;
                signal.Signal_Type__c = ServiceOpsConstants.SIGNAL_TYPE_SLA;
                signal.Risk_Level__c = riskLevel;
                signal.Status__c = ServiceOpsConstants.SIGNAL_STATUS_OPEN;
                signal.Is_Active_Signal__c = true;
                signal.Reason_Code__c = cm.IsViolated ? ServiceOpsConstants.REASON_SLA_BREACHED : ServiceOpsConstants.REASON_SLA_NEAR_BREACH;
                signal.Reason_Text__c = cm.IsViolated ? 'SLA Milestone has been breached.' : 'SLA Milestone is near breach.';
                signal.Milestone_Target_Date__c = cm.TargetDate;
                signal.Minutes_To_Breach__c = minutesToBreach;
                signal.Source_Record_Id__c = cm.Id;
                newSignals.add(signal);
            } else {
                healthyCaseIds.add(cm.CaseId);
            }
        }

        ServiceOpsSignalService.upsertSignals(newSignals);
        // Note: SLA resolution is tricky because one case might have multiple milestones.
        // For MVP, we'll resolve if no active risky milestones were found for the case IDs in this scope 
        // AND they aren't in the newSignals list.
        Set<Id> casesWithRisks = new Set<Id>();
        for (ServiceOps_Case_Signal__c s : newSignals) casesWithRisks.add(s.Case__c);
        
        Set<Id> casesToResolve = new Set<Id>(caseIds);
        casesToResolve.removeAll(casesWithRisks);
        
        ServiceOpsSignalService.resolveSignals(casesToResolve, ServiceOpsConstants.SIGNAL_TYPE_SLA);
    }
}
