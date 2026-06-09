/**
 * Class: ServiceOpsSignalService
 * Purpose: Handles retrieval and DML for Signal and Metadata records.
 * Package: ServiceOps Pulse
 * Security: Enforces User Mode for DML. Metadata access is read-only.
 */
public inherited sharing class ServiceOpsSignalService {
    
    @TestVisible
    private static ServiceOps_Setting__mdt mockSetting;
    @TestVisible
    private static List<ServiceOps_Risk_Rule__mdt> mockRules;

    /**
     * Fetches the primary ServiceOps Setting record.
     */
    public static ServiceOps_Setting__mdt getSettings() {
        if (Test.isRunningTest() && mockSetting != null) return mockSetting;
        List<ServiceOps_Setting__mdt> settings = [
            SELECT Reply_SLA_Hours__c, Queue_Aging_Threshold_Hours__c, 
                   Agent_Email_Domain__c, Scan_Frequency_Minutes__c,
                   No_Touch_Threshold_Hours__c, Near_Breach_Threshold_Minutes__c,
                   Closed_Status_Values__c, Reply_Time_Calculation_Mode__c,
                   Default_Business_Hours_Id__c
            FROM ServiceOps_Setting__mdt
            WHERE Is_Active__c = true
            LIMIT 1
        ];
        return settings.isEmpty() ? new ServiceOps_Setting__mdt() : settings[0];
    }

    /**
     * Fetches all active risk rules.
     */
    public static List<ServiceOps_Risk_Rule__mdt> getRiskRules() {
        if (Test.isRunningTest() && mockRules != null) return mockRules;
        return [
            SELECT Signal_Type__c, Min_Minutes__c, Max_Minutes__c, Risk_Level__c, 
                   Reason_Code__c, Suggested_Action_Template__c, Priority__c
            FROM ServiceOps_Risk_Rule__mdt
            WHERE Is_Active__c = true
            ORDER BY Priority__c DESC, Min_Minutes__c ASC
        ];
    }

    /**
     * Upserts a list of Case Signal records in User Mode.
     * Uses unique key logic (Case + Signal Type) to prevent duplicates.
     */
    public static void upsertSignals(List<ServiceOps_Case_Signal__c> signals) {
        if (signals.isEmpty()) return;

        Set<Id> caseIds = new Set<Id>();
        for (ServiceOps_Case_Signal__c s : signals) {
            caseIds.add(s.Case__c);
        }

        // Map existing open signals for these cases to prevent duplicates
        Map<String, ServiceOps_Case_Signal__c> existingSignalMap = new Map<String, ServiceOps_Case_Signal__c>();
        for (ServiceOps_Case_Signal__c s : [
            SELECT Id, Case__c, Signal_Type__c
            FROM ServiceOps_Case_Signal__c
            WHERE Case__c IN :caseIds 
            AND Status__c = :ServiceOpsConstants.SIGNAL_STATUS_OPEN
            WITH USER_MODE
        ]) {
            existingSignalMap.put(s.Case__c + '-' + s.Signal_Type__c, s);
        }

        List<ServiceOps_Case_Signal__c> signalsToUpsert = new List<ServiceOps_Case_Signal__c>();
        for (ServiceOps_Case_Signal__c s : signals) {
            String key = s.Case__c + '-' + s.Signal_Type__c;
            if (existingSignalMap.containsKey(key)) {
                s.Id = existingSignalMap.get(key).Id;
            } else {
                s.Detected_At__c = DateTime.now();
            }
            signalsToUpsert.add(s);
        }

        if (!signalsToUpsert.isEmpty()) {
            upsert as user signalsToUpsert;
        }
    }

    /**
     * Resolves open signals for cases in User Mode.
     */
    public static void resolveSignals(Set<Id> caseIds, String signalType) {
        if (caseIds.isEmpty()) return;

        List<ServiceOps_Case_Signal__c> signalsToResolve = [
            SELECT Id, Status__c, Is_Active_Signal__c, Resolved_At__c
            FROM ServiceOps_Case_Signal__c
            WHERE Case__c IN :caseIds 
            AND Signal_Type__c = :signalType 
            AND Status__c = :ServiceOpsConstants.SIGNAL_STATUS_OPEN
            WITH USER_MODE
        ];

        for (ServiceOps_Case_Signal__c s : signalsToResolve) {
            s.Status__c = ServiceOpsConstants.SIGNAL_STATUS_RESOLVED;
            s.Is_Active_Signal__c = false;
            s.Resolved_At__c = DateTime.now();
        }

        if (!signalsToResolve.isEmpty()) {
            update as user signalsToResolve;
        }
    }
}
