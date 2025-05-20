global class LeaveBalanceScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        String currentMonth = Date.today().year() + '-' + String.valueOf(Date.today().month()).leftPad(2, '0');
        List<Leave_Balance__c> balances = new List<Leave_Balance__c>();
        for (User u : [SELECT Id FROM User WHERE IsActive = true]) {
            Leave_Balance__c existingBalance = [SELECT Id, Leaves_Remaining__c 
                                               FROM Leave_Balance__c 
                                               WHERE Employee__c = :u.Id 
                                               AND Month__c = :currentMonth 
                                               LIMIT 1];
            if (existingBalance == null) {
                balances.add(new Leave_Balance__c(
                    Employee__c = u.Id,
                    Month__c = currentMonth,
                    Leaves_Remaining__c = 2
                ));
            } else {
                existingBalance.Leaves_Remaining__c += 2;
                balances.add(existingBalance);
            }
        }
        upsert balances;
    }
}