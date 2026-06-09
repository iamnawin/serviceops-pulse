/**
 * Class: ServiceOpsSetupController
 * Purpose: Exposes setup methods to the LWC Setup Wizard.
 * Package: ServiceOps Pulse
 * Security: Enforces User Mode for read. Setup write is via Metadata API.
 */
public inherited sharing class ServiceOpsSetupController {
    
    @AuraEnabled(cacheable=true)
    public static ServiceOps_Setting__mdt getSettings() {
        return ServiceOpsSignalService.getSettings();
    }

    @AuraEnabled
    public static void saveSettings(
        String agentDomain, 
        Decimal replySla, 
        Decimal queueAging, 
        Decimal nearBreach
    ) {
        Map<String, Object> values = new Map<String, Object>();
        values.put('Agent_Email_Domain__c', agentDomain);
        values.put('Reply_SLA_Hours__c', replySla);
        values.put('Queue_Aging_Threshold_Hours__c', queueAging);
        values.put('Near_Breach_Threshold_Minutes__c', nearBreach);
        values.put('Is_Active__c', true);

        ServiceOpsSetupService.saveSettings(values);
    }
}
