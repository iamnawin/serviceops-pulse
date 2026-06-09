/**
 * Class: ServiceOpsDashboardController
 * Purpose: Provides data for the ServiceOps Pulse LWC dashboards.
 * Package: ServiceOps Pulse
 * Security: Enforces User Mode for queries.
 */
public inherited sharing class ServiceOpsDashboardController {
    
    /**
     * Data wrapper for the executive summary.
     */
    public class ExecutiveSummary {
        @AuraEnabled public Integer totalReplyRisk {get;set;}
        @AuraEnabled public Integer totalQueueRisk {get;set;}
        @AuraEnabled public Integer totalSlaRisk {get;set;}
        @AuraEnabled public Integer totalHighRisk {get;set;}
        @AuraEnabled public Integer totalCriticalRisk {get;set;}
    }

    /**
     * Returns a summary of all active operational risks.
     */
    @AuraEnabled(cacheable=true)
    public static ExecutiveSummary getExecutiveSummary() {
        ExecutiveSummary summary = new ExecutiveSummary();
        summary.totalReplyRisk = 0;
        summary.totalQueueRisk = 0;
        summary.totalSlaRisk = 0;
        summary.totalHighRisk = 0;
        summary.totalCriticalRisk = 0;

        List<AggregateResult> results = [
            SELECT Signal_Type__c, Risk_Level__c, count(Id) total
            FROM ServiceOps_Case_Signal__c
            WHERE Status__c = :ServiceOpsConstants.SIGNAL_STATUS_OPEN
            WITH USER_MODE
            GROUP BY Signal_Type__c, Risk_Level__c
        ];

        for (AggregateResult ar : results) {
            String type = (String) ar.get('Signal_Type__c');
            String risk = (String) ar.get('Risk_Level__c');
            Integer count = (Integer) ar.get('total');

            if (type == ServiceOpsConstants.SIGNAL_TYPE_REPLY) summary.totalReplyRisk += count;
            if (type == ServiceOpsConstants.SIGNAL_TYPE_QUEUE) summary.totalQueueRisk += count;
            if (type == ServiceOpsConstants.SIGNAL_TYPE_SLA) summary.totalSlaRisk += count;

            if (risk == ServiceOpsConstants.RISK_LEVEL_HIGH) summary.totalHighRisk += count;
            if (risk == ServiceOpsConstants.RISK_LEVEL_CRITICAL) summary.totalCriticalRisk += count;
        }

        return summary;
    }

    /**
     * Returns a list of risky cases for a specific signal type.
     */
    @AuraEnabled(cacheable=true)
    public static List<ServiceOps_Case_Signal__c> getRiskyCases(String signalType) {
        return [
            SELECT Id, Case__c, Case__r.CaseNumber, Case__r.Subject, Case__r.Status, 
                   Risk_Level__c, Reason_Code__c, Time_Since_Customer_Reply_Min__c, 
                   Queue_Age_Min__c, Suggested_Action__c, Detected_At__c
            FROM ServiceOps_Case_Signal__c
            WHERE Status__c = :ServiceOpsConstants.SIGNAL_STATUS_OPEN
            AND Signal_Type__c = :signalType
            WITH USER_MODE
            ORDER BY Risk_Level__c DESC, Detected_At__c ASC
            LIMIT 50
        ];
    }
}
