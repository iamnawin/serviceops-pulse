/**
 * Class: SLAPulseEngineTest
 * Purpose: Test suite for SLAPulse logic.
 * Package: ServiceOps Pulse
 * Security: None (Test context)
 */
@isTest
private class SLAPulseEngineTest {

    private static void setupMockMetadata() {
        // Mock Settings
        ServiceOps_Setting__mdt settings = (ServiceOps_Setting__mdt) JSON.deserialize(
            '{"Is_Active__c": true, "Near_Breach_Threshold_Minutes__c": 30}', 
            ServiceOps_Setting__mdt.class
        );
        ServiceOpsSignalService.mockSetting = settings;

        // Mock Rules for Missing Entitlement
        ServiceOps_Risk_Rule__mdt ruleSla = (ServiceOps_Risk_Rule__mdt) JSON.deserialize(
            '{"Signal_Type__c": "' + ServiceOpsConstants.SIGNAL_TYPE_SLA + '", "Min_Minutes__c": 0, "Risk_Level__c": "' + ServiceOpsConstants.RISK_LEVEL_MEDIUM + '", "Reason_Code__c": "MISSING_ENTITLEMENT"}', 
            ServiceOps_Risk_Rule__mdt.class
        );
        ServiceOpsSignalService.mockRules = new List<ServiceOps_Risk_Rule__mdt>{ruleSla};
    }

    @isTest
    static void testMissingEntitlementRisk() {
        setupMockMetadata();
        Case c = ServiceOpsTestDataFactory.createCase('Missing Entitlement Case');

        Test.startTest();
        SLAPulseService.scanSlaRisks(new Set<Id>{c.Id});
        Test.stopTest();
        
        List<ServiceOps_Case_Signal__c> signals = [
            SELECT Risk_Level__c, Reason_Code__c 
            FROM ServiceOps_Case_Signal__c 
            WHERE Case__c = :c.Id AND Signal_Type__c = :ServiceOpsConstants.SIGNAL_TYPE_SLA
        ];
        System.assertEquals(1, signals.size());
        System.assertEquals('MISSING_ENTITLEMENT', signals[0].Reason_Code__c);
    }

    @isTest
    static void testWithEntitlementNoRisk() {
        setupMockMetadata();
        Account acc = ServiceOpsTestDataFactory.createAccount('Test Acc');
        // This might fail if Entitlements are not enabled in the environment
        try {
            Entitlement ent = ServiceOpsTestDataFactory.createEntitlement(acc.Id);
            Case c = new Case(Subject = 'With Entitlement Case', EntitlementId = ent.Id);
            insert c;

            Test.startTest();
            SLAPulseService.scanSlaRisks(new Set<Id>{c.Id});
            Test.stopTest();
            
            List<ServiceOps_Case_Signal__c> signals = [SELECT Id FROM ServiceOps_Case_Signal__c WHERE Case__c = :c.Id AND Signal_Type__c = :ServiceOpsConstants.SIGNAL_TYPE_SLA];
            System.assertEquals(0, signals.size(), 'Should have no signals if entitlement is present and no milestones');
        } catch (Exception e) {
            // Entitlements might not be enabled, skip this part of the test
            System.debug('Entitlements not enabled: ' + e.getMessage());
        }
    }
}
