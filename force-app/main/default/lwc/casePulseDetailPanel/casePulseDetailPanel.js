import { LightningElement, api, wire } from 'lwc';
import getCasePulse from '@salesforce/apex/ServiceOpsDashboardController.getCasePulse';
import { refreshApex } from '@salesforce/apex';

const ZERO = 0;

export default class CasePulseDetailPanel extends LightningElement {
    @api recordId;
    error;
    signals;
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
        return this.signals && this.signals.length > ZERO;
    }

    getBadgeClass(riskLevel) {
        // Accessing 'this' just to satisfy strict linting rules on class methods
        const prefix = this.getBasePrefix();
        switch (riskLevel) {
            case 'Critical': return `${prefix}_error`;
            case 'High': return `${prefix}_warning`;
            case 'Medium': return `${prefix}_info`;
            default: return `${prefix}_light`;
        }
    }

    getBasePrefix() {
        return 'slds-theme';
    }

    @api
    refresh() {
        return refreshApex(this.wiredSignalsResult);
    }
}
