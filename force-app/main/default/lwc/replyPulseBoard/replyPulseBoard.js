import { LightningElement, wire, api } from 'lwc';
import getRiskyCases from '@salesforce/apex/ServiceOpsDashboardController.getRiskyCases';
import { NavigationMixin } from 'lightning/navigation';

const COLS = [
    { label: 'Case', fieldName: 'caseUrl', type: 'url', typeAttributes: { label: { fieldName: 'CaseNumber' }, target: '_blank' } },
    { label: 'Subject', fieldName: 'Subject' },
    { label: 'Risk', fieldName: 'Risk_Level__c', type: 'text', cellAttributes: { class: { fieldName: 'riskClass' } } },
    { label: 'Waiting (Min)', fieldName: 'Time_Since_Customer_Reply_Min__c', type: 'number' },
    { label: 'Detected At', fieldName: 'Detected_At__c', type: 'date', typeAttributes: { hour: '2-digit', minute: '2-digit' } }
];

export default class ReplyPulseBoard extends NavigationMixin(LightningElement) {
    signals;
    error;
    columns = COLS;

    @wire(getRiskyCases, { signalType: 'Reply Risk' })
    wiredSignals({ error, data }) {
        if (data) {
            this.signals = data.map(record => ({
                ...record,
                caseUrl: `/${record.Case__c}`,
                CaseNumber: record.Case__r.CaseNumber,
                Subject: record.Case__r.Subject,
                riskClass: record.Risk_Level__c === 'High' || record.Risk_Level__c === 'Critical' ? 'slds-text-color_error slds-text-title_bold' : ''
            }));
            this.error = undefined;
        } else if (error) {
            this.error = 'Error loading reply risks';
            this.signals = undefined;
        }
    }
}
