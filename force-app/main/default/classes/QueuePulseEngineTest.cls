/**
 * Class: QueuePulseEngineTest
 * Purpose: Test suite for QueuePulse logic.
 * Package: ServiceOps Pulse
 * Security: None (Test context)
 */
@isTest
private class QueuePulseEngineTest {

    private static void setupMockMetadata() {
        // Mock Settings
        ServiceOps_Setting__mdt settings = (ServiceOps_Setting__mdt) JSON.deserialize(
            '{"Is_Active__c": true}', 
            ServiceOps_Setting__mdt.class
        );
        ServiceOpsSignalService.mockSetting = settings;

        // Mock Rules
        ServiceOps_Risk_Rule__mdt ruleHigh = (ServiceOps_Risk_Rule__mdt) JSON.deserialize(
            '{"Signal_Type__c": "' + ServiceOpsConstants.SIGNAL_TYPE_QUEUE + '", "Min_Minutes__c": 60, "Risk_Level__c": "' + ServiceOpsConstants.RISK_LEVEL_HIGH + '", "Reason_Code__c": "' + ServiceOpsConstants.REASON_QUEUE_STUCK + '", "Suggested_Action_Template__c": "Assign this case."}', 
            ServiceOps_Risk_Rule__mdt.class
        );
        ServiceOpsSignalService.mockRules = new List<ServiceOps_Risk_Rule__mdt>{ruleHigh};
    }

    @isTest
    static void testCaseInQueueHighRisk() {
        setupMockMetadata();
        
        // We can't easily backdate CreatedDate in Apex tests for standard objects.
        // However, we can mock the input to the evaluator or use a trick.
        // For the engine test, we will rely on the fact that if we set Min_Minutes to 0, 
        // even a newly created case in a queue will trigger it.
        
        // Update mock rule to 0 minutes
        ServiceOps_Risk_Rule__mdt ruleImmediate = (ServiceOps_Risk_Rule__mdt) JSON.deserialize(
            '{"Signal_Type__c": "' + ServiceOpsConstants.SIGNAL_TYPE_QUEUE + '", "Min_Minutes__c": 0, "Risk_Level__c": "' + ServiceOpsConstants.RISK_LEVEL_HIGH + '", "Reason_Code__c": "' + ServiceOpsConstants.REASON_QUEUE_STUCK + '"}', 
            ServiceOps_Risk_Rule__mdt.class
        );
        ServiceOpsSignalService.mockRules = new List<ServiceOps_Risk_Rule__mdt>{ruleImmediate};

        Group testQueue = ServiceOpsTestDataFactory.createQueue('Support Queue');
        Case c = ServiceOpsTestDataFactory.createCaseInQueue('Queue Risk Case', testQueue.Id);

        Test.startTest();
        QueuePulseService.scanQueueRisks(new Set<Id>{c.Id});
        Test.stopTest();
        
        List<ServiceOps_Case_Signal__c> signals = [
            SELECT Risk_Level__c, Signal_Type__c 
            FROM ServiceOps_Case_Signal__c 
            WHERE Case__c = :c.Id AND Signal_Type__c = :ServiceOpsConstants.SIGNAL_TYPE_QUEUE
        ];
        System.assertEquals(1, signals.size());
        System.assertEquals(ServiceOpsConstants.RISK_LEVEL_HIGH, signals[0].Risk_Level__c);
    }

    @isTest
    static void testCaseOwnedByUserNoRisk() {
        setupMockMetadata();
        Case c = ServiceOpsTestDataFactory.createCase('User Owned Case');

        Test.startTest();
        QueuePulseService.scanQueueRisks(new Set<Id>{c.Id});
        Test.stopTest();
        
        List<ServiceOps_Case_Signal__c> signals = [SELECT Id FROM ServiceOps_Case_Signal__c WHERE Case__c = :c.Id AND Signal_Type__c = :ServiceOpsConstants.SIGNAL_TYPE_QUEUE];
        System.assertEquals(0, signals.size(), 'Should have no queue signals for user-owned cases');
    }

    @isTest
    static void testBatchExecution() {
        setupMockMetadata();
        Group testQueue = ServiceOpsTestDataFactory.createQueue('Batch Queue');
        ServiceOpsTestDataFactory.createCaseInQueue('Batch Case 1', testQueue.Id);
        
        // Mock a 0 minute rule to ensure detection
        ServiceOps_Risk_Rule__mdt ruleImmediate = (ServiceOps_Risk_Rule__mdt) JSON.deserialize(
            '{"Signal_Type__c": "' + ServiceOpsConstants.SIGNAL_TYPE_QUEUE + '", "Min_Minutes__c": 0, "Risk_Level__c": "' + ServiceOpsConstants.RISK_LEVEL_HIGH + '"}', 
            ServiceOps_Risk_Rule__mdt.class
        );
        ServiceOpsSignalService.mockRules = new List<ServiceOps_Risk_Rule__mdt>{ruleImmediate};

        Test.startTest();
        Database.executeBatch(new ServiceOpsScanBatch());
        Test.stopTest();
        
        System.assert([SELECT count() FROM ServiceOps_Case_Signal__c] > 0);
    }
}
