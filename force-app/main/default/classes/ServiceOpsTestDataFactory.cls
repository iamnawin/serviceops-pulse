/**
 * Class: ServiceOpsTestDataFactory
 * Purpose: Utility for generating test data.
 * Package: ServiceOps Pulse
 * Security: None (Test context only)
 */
@isTest
public class ServiceOpsTestDataFactory {
    
    public static Case createCase(String subject) {
        Case c = new Case(Subject = subject, Status = 'New');
        insert c;
        return c;
    }

    public static List<Case> createCases(Integer count) {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < count; i++) {
            cases.add(new Case(Subject = 'Test Case ' + i, Status = 'New'));
        }
        insert cases;
        return cases;
    }

    public static EmailMessage createEmail(Id parentId, Boolean incoming, String address, DateTime messageDate) {
        EmailMessage em = new EmailMessage(
            ParentId = parentId,
            Incoming = incoming,
            FromAddress = address,
            ToAddress = incoming ? 'support@company.com' : 'customer@client.com',
            MessageDate = messageDate,
            Subject = 'Test Email',
            TextBody = 'Test Body',
            Status = '3'
        );
        insert em;
        return em;
    }

    public static Group createQueue(String name) {
        Group g = new Group(Name = name, Type = 'Queue');
        insert g;
        
        // Associate with Case object
        QueuesObject q = new QueuesObject(QueueId = g.Id, SObjectType = 'Case');
        insert q;
        
        return g;
    }

    public static Case createCaseInQueue(String subject, Id queueId) {
        Case c = new Case(Subject = subject, Status = 'New', OwnerId = queueId);
        insert c;
        return c;
    }
}
