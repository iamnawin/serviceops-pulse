import { LightningElement, api, wire } from 'lwc';
import getCasePulse from '@salesforce/apex/ServiceOpsDashboardController.getCasePulse';
import { refreshApex } from '@salesforce/apex';

export default class CasePulseDetailPanel extends LightningElement {
    @api recordId;
    signals;
    error;
    wiredSignalsResult;

    @wire(getCasePulse, { caseId: '$recordId' })
    wiredSignals(result) {
        this.wiredSignalsResult = result;
        if (result.data) {
            this.signals = result.data.map(record => ({
                ...record,
                riskBadgeClass: this.getBadgeClass(record.Risk_Level__c)
            }));
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.signals = undefined;
        }
    }

    get hasSignals() {
        return this.signals && this.signals.length > 0;
    }

    getBadgeClass(riskLevel) {
        switch (riskLevel) {
            case 'Critical': return 'slds-theme_error';
            case 'High': return 'slds-theme_warning';
            case 'Medium': return 'slds-theme_info';
            default: return 'slds-theme_light';
        }
    }

    @api
    refresh() {
        return refreshApex(this.wiredSignalsResult);
    }
}
