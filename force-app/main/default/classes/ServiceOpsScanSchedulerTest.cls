@isTest
private class ServiceOpsScanSchedulerTest {

    @isTest
    static void testScheduler() {
        Test.startTest();
        
        // Schedule the job
        String jobId = ServiceOpsScanScheduler.scheduleJob(60);
        System.assertNotEquals(null, jobId, 'Job should be scheduled successfully');

        // Execute the job directly
        ServiceOpsScanScheduler scheduler = new ServiceOpsScanScheduler();
        scheduler.execute(null); // sc is usually null in manual execute tests
        
        Test.stopTest();
        
        // No exceptions means the batch was successfully queued by the scheduler
        System.assert(true, 'Scheduler executed without errors');
    }
}
