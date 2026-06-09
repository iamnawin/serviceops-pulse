/**
 * Class: ServiceOpsScanScheduler
 * Purpose: Schedulable class to run the ServiceOps Scan Batch.
 * Package: ServiceOps Pulse
 * Security: Inherited sharing.
 */
public inherited sharing class ServiceOpsScanScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        // Default batch size of 50 to ensure EmailMessage queries don't hit limits
        Database.executeBatch(new ServiceOpsScanBatch(), 50);
    }

    /**
     * Utility method to schedule the job.
     */
    public static String scheduleJob(Integer frequencyMinutes) {
        String jobName = 'ServiceOps Pulse Scan Job';
        // Simple hourly schedule for MVP if frequency is not specified or too complex
        // In a real setup wizard, we would handle cron expressions.
        return System.schedule(jobName, '0 0 * * * ?', new ServiceOpsScanScheduler());
    }
}
