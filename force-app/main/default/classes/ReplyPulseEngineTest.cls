/**
 * Class: ReplyPulseEngineTest
 * Purpose: Test suite for ReplyPulse logic.
 * Package: ServiceOps Pulse
 * Security: None (Test context)
 */
@isTest
private class ReplyPulseEngineTest {

    @TestSetup
    static void setup() {
        // We use mocking for metadata, so no setup required for metadata records.
    }

    private static void setupMockMetadata() {
        // Mock Settings
        ServiceOps_Setting__mdt settings = (ServiceOps_Setting__mdt) JSON.deserialize(
            '{"Agent_Email_Domain__c": "company.com", "Is_Active__c": true}', 
            ServiceOps_Setting__mdt.class
        );
        ServiceOpsSignalService.mockSetting = settings;

        // Mock Rules
        ServiceOps_Risk_Rule__mdt ruleHigh = (ServiceOps_Risk_Rule__mdt) JSON.deserialize(
            '{"Signal_Type__c": "' + ServiceOpsConstants.SIGNAL_TYPE_REPLY + '", "Min_Minutes__c": 60, "Risk_Level__c": "' + ServiceOpsConstants.RISK_LEVEL_HIGH + '", "Reason_Code__c": "' + ServiceOpsConstants.REASON_REPLY_WAITING + '", "Suggested_Action_Template__c": "Critical: Reply now."}', 
            ServiceOps_Risk_Rule__mdt.class
        );
        ServiceOps_Risk_Rule__mdt ruleMed = (ServiceOps_Risk_Rule__mdt) JSON.deserialize(
            '{"Signal_Type__c": "' + ServiceOpsConstants.SIGNAL_TYPE_REPLY + '", "Min_Minutes__c": 30, "Max_Minutes__c": 59, "Risk_Level__c": "' + ServiceOpsConstants.RISK_LEVEL_MEDIUM + '", "Reason_Code__c": "' + ServiceOpsConstants.REASON_REPLY_WAITING + '"}', 
            ServiceOps_Risk_Rule__mdt.class
        );
        ServiceOpsSignalService.mockRules = new List<ServiceOps_Risk_Rule__mdt>{ruleHigh, ruleMed};
    }

    @isTest
    static void testCustomerRepliedLastHighRisk() {
        setupMockMetadata();
        Case c = ServiceOpsTestDataFactory.createCase('High Risk Case');
        
        // Agent replied 2 hours ago
        ServiceOpsTestDataFactory.createEmail(c.Id, false, 'agent@company.com', DateTime.now().addHours(-2));
        // Customer replied 70 minutes ago
        ServiceOpsTestDataFactory.createEmail(c.Id, true, 'customer@client.com', DateTime.now().addMinutes(-70));

        Test.startTest();
        ReplyPulseService.scanReplyRisks(new Set<Id>{c.Id});
        Test.stopTest();
        
        List<ServiceOps_Case_Signal__c> signals = [
            SELECT Risk_Level__c, Reason_Code__c, Last_Inbound_Email_Date__c, Source_Record_Id__c 
            FROM ServiceOps_Case_Signal__c 
            WHERE Case__c = :c.Id
        ];
        System.assertEquals(1, signals.size());
        System.assertEquals(ServiceOpsConstants.RISK_LEVEL_HIGH, signals[0].Risk_Level__c);
        System.assertEquals(ServiceOpsConstants.REASON_REPLY_WAITING, signals[0].Reason_Code__c);
        System.assertNotEquals(null, signals[0].Source_Record_Id__c);
    }

    @isTest
    static void testAgentRepliedLastNoRisk() {
        setupMockMetadata();
        Case c = ServiceOpsTestDataFactory.createCase('No Risk Case');
        
        // Customer replied 2 hours ago
        ServiceOpsTestDataFactory.createEmail(c.Id, true, 'customer@client.com', DateTime.now().addHours(-2));
        // Agent replied 1 hour ago
        ServiceOpsTestDataFactory.createEmail(c.Id, false, 'agent@company.com', DateTime.now().addHours(-1));

        Test.startTest();
        ReplyPulseService.scanReplyRisks(new Set<Id>{c.Id});
        Test.stopTest();
        
        List<ServiceOps_Case_Signal__c> signals = [SELECT Id FROM ServiceOps_Case_Signal__c WHERE Case__c = :c.Id];
        System.assertEquals(0, signals.size(), 'Should have no signals if agent replied last');
    }

    @isTest
    static void testExistingSignalResolution() {
        setupMockMetadata();
        Case c = ServiceOpsTestDataFactory.createCase('Resolution Case');
        
        // Initial state: Waiting on agent
        ServiceOpsTestDataFactory.createEmail(c.Id, true, 'customer@client.com', DateTime.now().addMinutes(-40));
        ReplyPulseService.scanReplyRisks(new Set<Id>{c.Id});
        
        System.assertEquals(1, [SELECT count() FROM ServiceOps_Case_Signal__c WHERE Case__c = :c.Id AND Status__c = :ServiceOpsConstants.SIGNAL_STATUS_OPEN]);

        // Agent replies
        ServiceOpsTestDataFactory.createEmail(c.Id, false, 'agent@company.com', DateTime.now());

        Test.startTest();
        ReplyPulseService.scanReplyRisks(new Set<Id>{c.Id});
        Test.stopTest();
        
        List<ServiceOps_Case_Signal__c> signals = [SELECT Status__c, Resolved_At__c FROM ServiceOps_Case_Signal__c WHERE Case__c = :c.Id];
        System.assertEquals(ServiceOpsConstants.SIGNAL_STATUS_RESOLVED, signals[0].Status__c);
        System.assertNotEquals(null, signals[0].Resolved_At__c);
    }

    @isTest
    static void testBulkProcessing() {
        setupMockMetadata();
        List<Case> cases = ServiceOpsTestDataFactory.createCases(50);
        Set<Id> caseIds = new Map<Id, Case>(cases).keySet();

        for (Case c : cases) {
            ServiceOpsTestDataFactory.createEmail(c.Id, true, 'customer@client.com', DateTime.now().addMinutes(-80));
        }

        Test.startTest();
        ReplyPulseService.scanReplyRisks(caseIds);
        Test.stopTest();
        
        System.assertEquals(50, [SELECT count() FROM ServiceOps_Case_Signal__c WHERE Risk_Level__c = :ServiceOpsConstants.RISK_LEVEL_HIGH]);
    }
}
