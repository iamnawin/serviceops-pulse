import { LightningElement, wire } from 'lwc';
import getExecutiveSummary from '@salesforce/apex/ServiceOpsDashboardController.getExecutiveSummary';

export default class ServiceOpsHome extends LightningElement {
    summary;
    error;

    @wire(getExecutiveSummary)
    wiredSummary({ error, data }) {
        if (data) {
            this.summary = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.summary = undefined;
        }
    }

    get totalCriticalAndHigh() {
        if (!this.summary) return 0;
        return (this.summary.totalHighRisk || 0) + (this.summary.totalCriticalRisk || 0);
    }
}
