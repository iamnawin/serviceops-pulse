import { LightningElement, wire, track } from 'lwc';
import getSettings from '@salesforce/apex/ServiceOpsSetupController.getSettings';
import saveSettings from '@salesforce/apex/ServiceOpsSetupController.saveSettings';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ServiceOpsSetupWizard extends LightningElement {
    @track currentStep = '1';
    @track settings = {
        Agent_Email_Domain__c: '',
        Reply_SLA_Hours__c: 4,
        Queue_Aging_Threshold_Hours__c: 24,
        Near_Breach_Threshold_Minutes__c: 30
    };
    isLoading = false;

    @wire(getSettings)
    wiredSettings({ error, data }) {
        if (data) {
            this.settings = { ...data };
        }
    }

    get isStep1() { return this.currentStep === '1'; }
    get isStep2() { return this.currentStep === '2'; }
    get isStep3() { return this.currentStep === '3'; }
    get isFirstStep() { return this.currentStep === '1'; }
    get isLastStep() { return this.currentStep === '3'; }

    handleDomainChange(event) { this.settings.Agent_Email_Domain__c = event.target.value; }
    handleReplySlaChange(event) { this.settings.Reply_SLA_Hours__c = event.target.value; }
    handleQueueAgingChange(event) { this.settings.Queue_Aging_Threshold_Hours__c = event.target.value; }
    handleNearBreachChange(event) { this.settings.Near_Breach_Threshold_Minutes__c = event.target.value; }

    handleNext() {
        const next = parseInt(this.currentStep, 10) + 1;
        this.currentStep = next.toString();
    }

    handlePrev() {
        const prev = parseInt(this.currentStep, 10) - 1;
        this.currentStep = prev.toString();
    }

    async handleSave() {
        this.isLoading = true;
        try {
            await saveSettings({
                agentDomain: this.settings.Agent_Email_Domain__c,
                replySla: this.settings.Reply_SLA_Hours__c,
                queueAging: this.settings.Queue_Aging_Threshold_Hours__c,
                nearBreach: this.settings.Near_Breach_Threshold_Minutes__c
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Settings deployment initiated. It may take a minute to reflect.',
                variant: 'success'
            }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Unable to save settings: ' + error.body.message,
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }
}
