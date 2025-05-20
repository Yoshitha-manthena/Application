public with sharing class LeaveRequestController {
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
                Employee__c = UserInfo.getUserId(),
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
                WHERE Employee__c = :UserInfo.getUserId() 
                ORDER BY CreatedDate DESC];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getLeaveBalance() {
        Map<String, Decimal> balanceMap = new Map<String, Decimal>();
        Decimal totalLeaves = 0;
        List<Leave_Balance__c> balances = [SELECT Month__c, Leaves_Remaining__c 
                                          FROM Leave_Balance__c 
                                          WHERE Employee__c = :UserInfo.getUserId()];
        for (Leave_Balance__c balance : balances) {
            balanceMap.put(balance.Month__c, balance.Leaves_Remaining__c);
            totalLeaves += balance.Leaves_Remaining__c;
        }
        balanceMap.put('Total', totalLeaves);
        return balanceMap;
    }
}