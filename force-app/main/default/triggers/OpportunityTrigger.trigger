trigger OpportunityTrigger on Opportunity (before update) {
    switch on System.Trigger.OperationType {
        when BEFORE_UPDATE {
            OpportunityTriggerHandler.restrictChangeInOpportunityWhenAccountTypeIsProspect(Trigger.newMap, Trigger.oldMap);
        }
    }
}