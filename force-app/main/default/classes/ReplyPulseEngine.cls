/**
 * Class: ReplyPulseEngine
 * Purpose: Detects if an open case is waiting on an agent response after a customer email.
 * Package: ServiceOps Pulse
 * Security: Enforces User Mode for queries.
 */
public inherited sharing class ReplyPulseEngine {
    
    /**
     * Entry point to process cases for Reply Risk.
     */
    public static void processCases(Set<Id> caseIds) {
        if (caseIds.isEmpty()) return;

        ServiceOps_Setting__mdt settings = ServiceOpsSignalService.getSettings();
        Map<Id, List<EmailMessage>> caseToEmails = getCaseEmailMap(caseIds);

        List<ServiceOps_Case_Signal__c> newSignals = new List<ServiceOps_Case_Signal__c>();
        Set<Id> healthyCaseIds = new Set<Id>();

        for (Id caseId : caseIds) {
            processSingleCase(caseId, caseToEmails.get(caseId), settings, newSignals, healthyCaseIds);
        }

        ServiceOpsSignalService.upsertSignals(newSignals);
        ServiceOpsSignalService.resolveSignals(healthyCaseIds, ServiceOpsConstants.SIGNAL_TYPE_REPLY);
    }

    /**
     * Queries and groups latest EmailMessages for the given cases.
     */
    private static Map<Id, List<EmailMessage>> getCaseEmailMap(Set<Id> caseIds) {
        Map<Id, List<EmailMessage>> caseToEmails = new Map<Id, List<EmailMessage>>();
        for (EmailMessage em : [
            SELECT ParentId, MessageDate, Incoming, FromAddress, ToAddress
            FROM EmailMessage
            WHERE ParentId IN :caseIds
            WITH USER_MODE
            ORDER BY MessageDate DESC
        ]) {
            if (!caseToEmails.containsKey(em.ParentId)) {
                caseToEmails.put(em.ParentId, new List<EmailMessage>());
            }
            caseToEmails.get(em.ParentId).add(em);
        }
        return caseToEmails;
    }

    /**
     * Evaluates a single case for reply risk.
     */
    private static void processSingleCase(Id caseId, List<EmailMessage> emails, ServiceOps_Setting__mdt settings, 
                                          List<ServiceOps_Case_Signal__c> newSignals, Set<Id> healthyCaseIds) {
        
        if (emails == null || emails.isEmpty()) {
            healthyCaseIds.add(caseId);
            return;
        }

        EmailMessage latestInbound = null;
        EmailMessage latestOutbound = null;
        String agentDomain = settings.Agent_Email_Domain__c;

        for (EmailMessage em : emails) {
            if (em.Incoming && latestInbound == null) {
                if (String.isBlank(agentDomain) || !em.FromAddress.contains(agentDomain)) {
                    latestInbound = em;
                }
            } else if (!em.Incoming && latestOutbound == null) {
                latestOutbound = em;
            }
            if (latestInbound != null && latestOutbound != null) break;
        }

        if (latestInbound != null && (latestOutbound == null || latestInbound.MessageDate > latestOutbound.MessageDate)) {
            Long waitingTimeMin = (DateTime.now().getTime() - latestInbound.MessageDate.getTime()) / 60000;
            ServiceOps_Case_Signal__c signal = ServiceOpsSignalEvaluator.evaluateRisk(caseId, ServiceOpsConstants.SIGNAL_TYPE_REPLY, waitingTimeMin);

            if (signal != null) {
                signal.Last_Inbound_Email_Date__c = latestInbound.MessageDate;
                signal.Source_Record_Id__c = latestInbound.Id;
                if (latestOutbound != null) signal.Last_Outbound_Email_Date__c = latestOutbound.MessageDate;
                newSignals.add(signal);
            } else {
                healthyCaseIds.add(caseId);
            }
        } else {
            healthyCaseIds.add(caseId);
        }
    }
}
