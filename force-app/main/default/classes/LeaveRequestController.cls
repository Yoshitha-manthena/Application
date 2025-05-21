public with sharing class LeaveRequestController {
    // Existing methods (submitLeaveRequest, getAppliedRequests, getLeaveBalance) remain unchanged

    @AuraEnabled
    public static String submitLeaveRequest(String typeOfLeave, Date startDate, Date endDate, String reason) {
        try {
            if (startDate < Date.today()) {
                throw new AuraHandledException('Start date cannot be in the past.');
            }
            if (endDate < startDate) {
                throw new AuraHandledException('End date must be after start date.');
            }
            Leave_Request__c leave = new Leave_Request__c(
                Type_of_Leave__c = typeOfLeave,
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Reason__c = reason,
                Emploee__c = UserInfo.getUserId(),
                Status__c = 'Pending'
            );
            insert leave;
            return 'Leave request submitted successfully!';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Leave_Request__c> getAppliedRequests() {
        return [SELECT Type_of_Leave__c, Start_Date__c, End_Date__c, Reason__c, Status__c 
                FROM Leave_Request__c 
                WHERE Emploee__c = :UserInfo.getUserId() 
                ORDER BY CreatedDate DESC];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getLeaveBalance() {
        Map<String, Decimal> balanceMap = new Map<String, Decimal>();
        Decimal totalLeaves = 0;
        List<Leave_Balance__c> balances = [SELECT Month__c, Leaves_Remaining__c 
                                           FROM Leave_Balance__c 
                                           WHERE Emploee__c = :UserInfo.getUserId()];
        for (Leave_Balance__c balance : balances) {
            balanceMap.put(balance.Month__c, balance.Leaves_Remaining__c);
            totalLeaves += balance.Leaves_Remaining__c;
        }
        balanceMap.put('Total', totalLeaves);
        return balanceMap;
    }

    // New method to update leave balance on approval
    @AuraEnabled
    public static void updateLeaveBalance(String leaveRequestId) {
        try {
            Leave_Request__c request = [SELECT Start_Date__c, End_Date__c, Status__c 
                                       FROM Leave_Request__c 
                                       WHERE Id = :leaveRequestId LIMIT 1];
            if (request.Status__c != 'Approved') {
                return; // Only process approved requests
            }
            String month = request.Start_Date__c.year() + '-' + String.valueOf(request.Start_Date__c.month()).leftPad(2, '0');
            Integer days = request.Start_Date__c.daysBetween(request.End_Date__c) + 1; // Include end date
            Leave_Balance__c balance = [SELECT Leaves_Remaining__c 
                                       FROM Leave_Balance__c 
                                       WHERE Emploee__c = :UserInfo.getUserId() 
                                       AND Month__c = :month 
                                       LIMIT 1];
            if (balance == null) {
                throw new AuraHandledException('No leave balance found for ' + month);
            }
            if (balance.Leaves_Remaining__c < days) {
                throw new AuraHandledException('Insufficient leave balance for ' + month);
            }
            balance.Leaves_Remaining__c -= days;
            update balance;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating leave balance: ' + e.getMessage());
        }
    }
}