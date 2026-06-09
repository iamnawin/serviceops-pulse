@isTest
private class ServiceOpsDashboardCtrlTest {

    @isTest
    static void testGetExecutiveSummaryAndRiskyCases() {
        // Create test cases
        Case c1 = ServiceOpsTestDataFactory.createCase('Reply Risk Case');
        Case c2 = ServiceOpsTestDataFactory.createCase('Queue Risk Case');
        
        // Insert some dummy signals
        List<ServiceOps_Case_Signal__c> signals = new List<ServiceOps_Case_Signal__c>{
            new ServiceOps_Case_Signal__c(
                Case__c = c1.Id,
                Signal_Type__c = ServiceOpsConstants.SIGNAL_TYPE_REPLY,
                Risk_Level__c = ServiceOpsConstants.RISK_LEVEL_HIGH,
                Status__c = ServiceOpsConstants.SIGNAL_STATUS_OPEN,
                Is_Active_Signal__c = true
            ),
            new ServiceOps_Case_Signal__c(
                Case__c = c2.Id,
                Signal_Type__c = ServiceOpsConstants.SIGNAL_TYPE_QUEUE,
                Risk_Level__c = ServiceOpsConstants.RISK_LEVEL_CRITICAL,
                Status__c = ServiceOpsConstants.SIGNAL_STATUS_OPEN,
                Is_Active_Signal__c = true
            )
        };
        insert signals;

        Test.startTest();
        
        // Test Executive Summary
        ServiceOpsDashboardController.ExecutiveSummary summary = ServiceOpsDashboardController.getExecutiveSummary();
        
        System.assertEquals(1, summary.totalReplyRisk, 'Should have 1 Reply Risk');
        System.assertEquals(1, summary.totalQueueRisk, 'Should have 1 Queue Risk');
        System.assertEquals(0, summary.totalSlaRisk, 'Should have 0 SLA Risk');
        System.assertEquals(1, summary.totalHighRisk, 'Should have 1 High Risk');
        System.assertEquals(1, summary.totalCriticalRisk, 'Should have 1 Critical Risk');

        // Test Risky Cases List
        List<ServiceOps_Case_Signal__c> replySignals = ServiceOpsDashboardController.getRiskyCases(ServiceOpsConstants.SIGNAL_TYPE_REPLY);
        System.assertEquals(1, replySignals.size(), 'Should return 1 Reply Risk case');

        // Test Case Pulse Detail
        List<ServiceOps_Case_Signal__c> pulseDetail = ServiceOpsDashboardController.getCasePulse(c1.Id);
        System.assertEquals(1, pulseDetail.size(), 'Should return 1 active signal for the specific case');
        
        Test.stopTest();
    }
}
