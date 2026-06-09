@isTest
private class ServiceOpsSignalEvaluatorTest {

    @isTest
    static void testEvaluateRisk() {
        // Mock Rules
        ServiceOps_Risk_Rule__mdt ruleHigh = (ServiceOps_Risk_Rule__mdt) JSON.deserialize(
            '{"Signal_Type__c": "' + ServiceOpsConstants.SIGNAL_TYPE_REPLY + '", "Min_Minutes__c": 60, "Max_Minutes__c": 9999, "Risk_Level__c": "' + ServiceOpsConstants.RISK_LEVEL_HIGH + '", "Reason_Code__c": "HIGH_RISK", "Priority__c": 1}', 
            ServiceOps_Risk_Rule__mdt.class
        );
        ServiceOps_Risk_Rule__mdt ruleMed = (ServiceOps_Risk_Rule__mdt) JSON.deserialize(
            '{"Signal_Type__c": "' + ServiceOpsConstants.SIGNAL_TYPE_REPLY + '", "Min_Minutes__c": 30, "Max_Minutes__c": 59, "Risk_Level__c": "' + ServiceOpsConstants.RISK_LEVEL_MEDIUM + '", "Reason_Code__c": "MED_RISK", "Priority__c": 2}', 
            ServiceOps_Risk_Rule__mdt.class
        );
        ServiceOpsSignalService.mockRules = new List<ServiceOps_Risk_Rule__mdt>{ruleHigh, ruleMed};

        Case c = ServiceOpsTestDataFactory.createCase('Eval Case');

        Test.startTest();
        
        // Test High Risk (70 minutes)
        ServiceOps_Case_Signal__c signalHigh = ServiceOpsSignalEvaluator.evaluateRisk(c.Id, ServiceOpsConstants.SIGNAL_TYPE_REPLY, 70);
        System.assertEquals(ServiceOpsConstants.RISK_LEVEL_HIGH, signalHigh.Risk_Level__c);
        
        // Test Medium Risk (45 minutes)
        ServiceOps_Case_Signal__c signalMed = ServiceOpsSignalEvaluator.evaluateRisk(c.Id, ServiceOpsConstants.SIGNAL_TYPE_REPLY, 45);
        System.assertEquals(ServiceOpsConstants.RISK_LEVEL_MEDIUM, signalMed.Risk_Level__c);

        // Test No Risk (10 minutes)
        ServiceOps_Case_Signal__c signalNone = ServiceOpsSignalEvaluator.evaluateRisk(c.Id, ServiceOpsConstants.SIGNAL_TYPE_REPLY, 10);
        System.assertEquals(null, signalNone, 'Should return null when no rule matches');

        // Test Queue Risk Branch
        ServiceOps_Risk_Rule__mdt ruleQueue = (ServiceOps_Risk_Rule__mdt) JSON.deserialize(
            '{"Signal_Type__c": "' + ServiceOpsConstants.SIGNAL_TYPE_QUEUE + '", "Min_Minutes__c": 0, "Risk_Level__c": "' + ServiceOpsConstants.RISK_LEVEL_CRITICAL + '"}', 
            ServiceOps_Risk_Rule__mdt.class
        );
        ServiceOpsSignalService.mockRules = new List<ServiceOps_Risk_Rule__mdt>{ruleQueue};
        ServiceOps_Case_Signal__c signalQueue = ServiceOpsSignalEvaluator.evaluateRisk(c.Id, ServiceOpsConstants.SIGNAL_TYPE_QUEUE, 100);
        System.assertEquals(100, signalQueue.Queue_Age_Min__c);

        Test.stopTest();
    }
}
