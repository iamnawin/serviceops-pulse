import { LightningElement, wire } from 'lwc';
import getExecutiveSummary from '@salesforce/apex/ServiceOpsDashboardController.getExecutiveSummary';

const ZERO = 0;

export default class ServiceOpsHome extends LightningElement {
    error;
    summary;

    @wire(getExecutiveSummary)
    wiredSummary({ data, error }) {
        if (data) {
            this.summary = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.summary = undefined;
        }
    }

    get totalCriticalAndHigh() {
        if (!this.summary) {
            return ZERO;
        }
        return (this.summary.totalHighRisk || ZERO) + (this.summary.totalCriticalRisk || ZERO);
    }
}
