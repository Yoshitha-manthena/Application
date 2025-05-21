trigger LeaveRequestTrigger on Leave_Request__c (after update) {
    for (Leave_Request__c request : Trigger.new) {
        Leave_Request__c oldRequest = Trigger.oldMap.get(request.Id);
        if (request.Status__c == 'Approved' && oldRequest.Status__c != 'Approved') {
            LeaveRequestController.updateLeaveBalance(request.Id);
        }
    }
}