import { LightningElement, track, wire } from 'lwc';
import getPendingRequestsForManager from '@salesforce/apex/LeaveRequestController.getPendingRequestsForManager';
import processLeaveRequest from '@salesforce/apex/LeaveRequestController.processLeaveRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class ManagerDashboard extends LightningElement {
    @track pendingRequests = [];
    wiredRequestsResult;

    @wire(getPendingRequestsForManager)
    wiredPendingRequests(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            this.pendingRequests = result.data;
        } else if (result.error) {
            this.showToast('Error', result.error.body.message, 'error');
        }
    }

    handleApprove(event) {
        const requestId = event.target.dataset.id;
        this.processRequest(requestId, 'Approved');
    }

    handleReject(event) {
        const requestId = event.target.dataset.id;
        this.processRequest(requestId, 'Rejected');
    }

    processRequest(requestId, status) {
        processLeaveRequest({ leaveRequestId: requestId, status })
            .then(result => {
                this.showToast('Success', result, 'success');
                return refreshApex(this.wiredRequestsResult);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(evt);
    }
}