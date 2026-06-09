/**
 * Class: ServiceOpsSetupService
 * Purpose: Handles the deployment of Custom Metadata for ServiceOps Pulse settings.
 * Package: ServiceOps Pulse
 * Security: Uses Metadata.Operations for native deployment.
 */
public inherited sharing class ServiceOpsSetupService {
    
    /**
     * Deploys an update to the ServiceOps_Setting.Default record.
     */
    public static void saveSettings(Map<String, Object> fieldValues) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'ServiceOps_Setting.Default';
        customMetadata.label = 'Default Settings';

        for (String fieldName : fieldValues.keySet()) {
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = fieldName;
            customField.value = fieldValues.get(fieldName);
            customMetadata.values.add(customField);
        }

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);

        if (!Test.isRunningTest()) {
            Metadata.Operations.enqueueDeployment(mdContainer, null);
        }
    }
}
