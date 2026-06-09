/**
 * Class: ServiceOpsSignalEvaluator
 * Purpose: Evaluates raw metrics against risk rules to determine risk level.
 * Package: ServiceOps Pulse
 * Security: None (Processing only)
 */
public inherited sharing class ServiceOpsSignalEvaluator {
    
    /**
     * Evaluates a raw age (in minutes) against risk rules for a specific signal type.
     * Returns a ServiceOps_Case_Signal__c record if a risk is detected.
     */
    public static ServiceOps_Case_Signal__c evaluateRisk(Id caseId, String signalType, Long ageMinutes) {
        List<ServiceOps_Risk_Rule__mdt> allRules = ServiceOpsSignalService.getRiskRules();
        
        ServiceOps_Risk_Rule__mdt matchingRule = null;
        
        // Rules are ordered by Priority DESC, Min_Minutes ASC.
        // We find the first rule that matches the age range.
        for (ServiceOps_Risk_Rule__mdt rule : allRules) {
            if (rule.Signal_Type__c != signalType) continue;

            Boolean minMatch = (rule.Min_Minutes__c == null || ageMinutes >= rule.Min_Minutes__c);
            Boolean maxMatch = (rule.Max_Minutes__c == null || ageMinutes <= rule.Max_Minutes__c);

            if (minMatch && maxMatch) {
                matchingRule = rule;
                break; // Use the highest priority rule that matches
            }
        }

        if (matchingRule == null) return null;

        ServiceOps_Case_Signal__c signal = new ServiceOps_Case_Signal__c();
        signal.Case__c = caseId;
        signal.Signal_Type__c = signalType;
        signal.Risk_Level__c = matchingRule.Risk_Level__c;
        signal.Status__c = ServiceOpsConstants.SIGNAL_STATUS_OPEN;
        signal.Is_Active_Signal__c = true;
        signal.Reason_Code__c = matchingRule.Reason_Code__c;
        signal.Suggested_Action__c = matchingRule.Suggested_Action_Template__c;
        
        if (signalType == ServiceOpsConstants.SIGNAL_TYPE_REPLY) {
            signal.Time_Since_Customer_Reply_Min__c = ageMinutes;
        } else if (signalType == ServiceOpsConstants.SIGNAL_TYPE_QUEUE) {
            signal.Queue_Age_Min__c = ageMinutes;
        }

        return signal;
    }
}
