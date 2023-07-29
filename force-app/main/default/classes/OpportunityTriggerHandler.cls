/**
 * @description       : Trigger Handler for OpportunityTrigger
 * @author            : soomjeet.sahoo
 * @last modified on  : 07-29-2023
 * @last modified by  : soomjeet.sahoo
**/
public with sharing class OpportunityTriggerHandler {
    public static Boolean byPassOpportunityTrigger = false;
    private static final Set<String> ACCOUNT_TYPES_TO_BE_IGNORED_SET = new Set<String>{'Prospect'};
    private static final Set<String> FIELDS_TO_BE_IGNORED_FROM_VALIDATION_SET = new Set<String>{'Description'};
    private static final String VALIDATION_MESSAGE = 'When Account Type is Prospect,Opportunity cannot be updated.';

    /**
    * @description : Restricts changes on any field on Opportunity except description field, If the Account Type is Prospect. 
    * @author soomjeet.sahoo | 07-29-2023 
    * @param newOptyMap : Trigger.NewMap
    * @param oldOptyMap : Trigger.OldMap
    **/
    public static void restrictChangeInOpportunityWhenAccountTypeIsProspect(Map<Id,Opportunity> newOptyMap,Map<Id,Opportunity> oldOptyMap) {
        if(byPassOpportunityTrigger) return;
        try {
            Set<Id> associatedAccountIdSet = new Set<Id>();
            Set<Id> accountIdsWithRestrictiveType = new Set<Id>();
            Map<Id,String> accountId2TypeMap = new Map<Id,String>();

            //Getting all the account Ids to a Set
            for (Opportunity opp : newOptyMap.values()) {
                associatedAccountIdSet.add(opp.AccountId);
            }

            //Querying to filter the accounts based on type mentioned.
            for(Account acc : [SELECT Id FROM Account WHERE Id in: associatedAccountIdSet AND Type in: ACCOUNT_TYPES_TO_BE_IGNORED_SET WITH SECURITY_ENFORCED]){
                accountIdsWithRestrictiveType.add(acc.Id);
            }

            //Performing the addError logic
            for (Opportunity opp : newOptyMap.values()) {
                if(accountIdsWithRestrictiveType.contains(opp.AccountId) && areTwoOpportunityRecordsNotEqual(oldOptyMap.get(opp.Id),opp)){
                    opp.addError(VALIDATION_MESSAGE);
                }
            }

        } catch (Exception exp) {
            System.debug('[-] Exp :'+exp.getCause()+' : '+exp.getStackTraceString());
        }    
    }

    /**
    * @description : Return True if both Opportunities are not equal.
    * @author soomjeet.sahoo | 07-29-2023 
    * @param oldOpp : Old Version of opportunity record
    * @param newOpp : New/Current Version of opportunity record
    * @return Boolean 
    **/
    private static Boolean areTwoOpportunityRecordsNotEqual(Opportunity oldOpp,Opportunity newOpp){
        Boolean valToReturn = false;
        
        //modifying old opportunity
        Opportunity oldOptyModded = removeFieldsToIgnoreFromOpportunityRecord(oldOpp,FIELDS_TO_BE_IGNORED_FROM_VALIDATION_SET);
        
        //modifying new opportunity
        Opportunity newOptyModded = removeFieldsToIgnoreFromOpportunityRecord(newOpp,FIELDS_TO_BE_IGNORED_FROM_VALIDATION_SET);

        //checking if there is a change in opportunity on each field basis
        for(String key : newOptyModded.getPopulatedFieldsAsMap().KeySet()){
            if(oldOptyModded.get(key) != newOptyModded.get(key)){
                valToReturn = true;
            }
        }

        return valToReturn;
    }


    /**
    * @description : Removes the Fields that are not required for validating and created a mock Opportunity with removed fields.
    * @author soomjeet.sahoo | 07-29-2023 
    * @param record : opportunity Record to be treated
    * @param fieldsToIgnore : fields to be removed from record
    * @return Opportunity 
    **/
    private static Opportunity removeFieldsToIgnoreFromOpportunityRecord(Opportunity record,Set<String> fieldsToIgnore) {
        //making a clone of existing record
        Map<String,Object> modMap = record.getPopulatedFieldsAsMap().clone();
        
        //removing the fields mentioned in set from the cloned Map
        for(String str : fieldsToIgnore){
            modMap.remove(str);
        }
        
        return (Opportunity)JSON.deserialize(JSON.serialize(modMap),Opportunity.class);
    }

}