import { LightningElement, track, wire } from 'lwc';
import submitLeaveRequest from '@salesforce/apex/LeaveRequestController.submitLeaveRequest';
import getAppliedRequests from '@salesforce/apex/LeaveRequestController.getAppliedRequests';
import getLeaveBalance from '@salesforce/apex/LeaveRequestController.getLeaveBalance';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeaveDashboard extends LightningElement {
    @track activeTab = 'newLeave';
    @track isNewLeave = true;
    @track isAppliedRequests = false;
    @track isLeaveHistory = false;
    @track newLeaveClass = 'active';
    @track appliedRequestsClass = '';
    @track leaveHistoryClass = '';
    @track formData = { leaveType: '', startDate: '', endDate: '', reason: '' };
    @track formMessage = '';
    @track appliedRequests = [];
    @track leaveBalances = [];
    @track totalLeaves = 0;
    today = new Date().toISOString().split('T')[0];

    @wire(getAppliedRequests)
    wiredAppliedRequests({ error, data }) {
        if (data) {
            this.appliedRequests = data;
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    @wire(getLeaveBalance)
    wiredLeaveBalance({ error, data }) {
        if (data) {
            this.leaveBalances = Object.keys(data).filter(key => key !== 'Total').map(key => ({
                month: key,
                leaves: data[key]
            }));
            this.totalLeaves = data['Total'];
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    handleTabChange(event) {
        const tab = event.target.dataset.tab;
        this.activeTab = tab;
        this.isNewLeave = tab === 'newLeave';
        this.isAppliedRequests = tab === 'appliedRequests';
        this.isLeaveHistory = tab === 'leaveHistory';
        this.newLeaveClass = tab === 'newLeave' ? 'active' : '';
        this.appliedRequestsClass = tab === 'appliedRequests' ? 'active' : '';
        this.leaveHistoryClass = tab === 'leaveHistory' ? 'active' : '';
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.formData[field] = event.target.value;
    }

    handleSubmit() {
        const { leaveType, startDate, endDate, reason } = this.formData;
        if (!leaveType || !startDate || !endDate) {
            this.formMessage = 'Please fill all required fields.';
            return;
        }
        submitLeaveRequest({ typeOfLeave: leaveType, startDate, endDate, reason })
            .then(result => {
                this.formMessage = result;
                this.resetForm();
                this.showToast('Success', result, 'success');
            })
            .catch(error => {
                this.formMessage = error.body.message;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleCancel() {
        this.resetForm();
        this.formMessage = '';
    }

    resetForm() {
        this.formData = { leaveType: '', startDate: '', endDate: '', reason: '' };
        const inputs = this.template.querySelectorAll('input, select, textarea');
        inputs.forEach(input => (input.value = ''));
    }

    handleLogout() {
        window.location.href = '/secur/logout.jsp';
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(evt);
    }
}