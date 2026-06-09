import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRiskyCases from '@salesforce/apex/ServiceOpsDashboardController.getRiskyCases';

const COLS = [
    { fieldName: 'caseUrl', label: 'Case', type: 'url', typeAttributes: { label: { fieldName: 'CaseNumber' }, target: '_blank' } },
    { fieldName: 'Subject', label: 'Subject' },
    { cellAttributes: { class: { fieldName: 'riskClass' } }, fieldName: 'Risk_Level__c', label: 'Risk', type: 'text' },
    { fieldName: 'Time_Since_Customer_Reply_Min__c', label: 'Waiting (Min)', type: 'number' },
    { fieldName: 'Detected_At__c', label: 'Detected At', type: 'date', typeAttributes: { hour: '2-digit', minute: '2-digit' } }
];

export default class ReplyPulseBoard extends NavigationMixin(LightningElement) {
    columns = COLS;
    error;
    signals;

    @wire(getRiskyCases, { signalType: 'Reply Risk' })
    wiredSignals({ data, error }) {
        if (data) {
            this.signals = data.map(record => ({
                ...record,
                CaseNumber: record.Case__r.CaseNumber,
                Subject: record.Case__r.Subject,
                caseUrl: `/${record.Case__c}`,
                riskClass: record.Risk_Level__c === 'High' || record.Risk_Level__c === 'Critical' ? 'slds-text-color_error slds-text-title_bold' : ''
            }));
            this.error = undefined;
        } else if (error) {
            this.error = 'Error loading reply risks';
            this.signals = undefined;
        }
    }
}
