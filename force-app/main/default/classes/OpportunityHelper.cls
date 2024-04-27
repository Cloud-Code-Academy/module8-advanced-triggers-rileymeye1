/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-27-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OpportunityHelper {

    // Set the default Type for new opportunities
    public static void setDefualtType(List<Opportunity> newOpps){
        for (Opportunity opp : newOpps) {
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }
    }

    public static void validateAmount(List<Opportunity> newOpps) {
        // When an opportunity is updated validate that the amount is greater than 5000.
        for(Opportunity opp : newOpps){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    public static void setPrimaryContact(List<Opportunity> newOpps) {
        // When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : newOpps){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId
                                                            FROM Contact
                                                            WHERE AccountId IN :accountIds AND Title = 'CEO'
                                                            ORDER BY FirstName ASC]);
        
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
        
        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }
        
        for(Opportunity opp : newOpps){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }

    public static void appendStageChanges(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppsMap) {
        // Append Stage changes in Opportunity Description
        for (Opportunity opp : newOpps) {
            // Get old Opportunity
            Opportunity oldOpp = oldOppsMap.get(opp.Id);
            if (opp.StageName != null && oldOpp.StageName != opp.StageName){
                opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
            }
        }
    }

    public static void preventOppDeletion(List<Opportunity> oldOpps) {
        for(Opportunity opp : oldOpps) {
            if (opp.IsClosed) {
                opp.addError('Cannot delete closed opportunity');
            }
        }
    }

    public static void createNewTask(List<Opportunity> newOpps) {
        // Create a new Task for newly inserted Opportunities
        List<Task> newTasks = new List<Task>();
        for (Opportunity opp : newOpps){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            newTasks.add(tsk);
        }
        Database.insert(newTasks, accessLevel.USER_MODE);
    }

    // Sends an email notification to the owner of the Opportunity when it gets deleted.
    // Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> oldOpps) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Id> ownerIds = new List<Id>();
        for (Opportunity opp : oldOpps) {
            ownerIds.add(opp.OwnerId);
        }
        
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email
                                                    FROM User
                                                    WHERE Id = :ownerIds]);
        for (Opportunity opp : oldOpps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {userMap.get(opp.OwnerId).Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    // Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    // Only updates the Opportunities that don't already have a primary contact.
    public static void assignPrimaryContact(Map<Id,Opportunity> newOppMap) {        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        List<Id> accIdList = new List<Id>();
        for (Id key : newOppMap.keySet()){
            accIdList.add(newOppMap.get(key).AccountId);
        }

        Map<Id, Account> contactsByAccount = new Map<Id, Account>([SELECT Id, (SELECT Id, AccountId
                                                                            FROM Contacts
                                                                            WHERE Title = 'VP Sales'
                                                                            LIMIT 1)
                                                            FROM Account
                                                            WHERE Id = :accIdList]);
        
        for (Opportunity opp : newOppMap.values()){            
            Contact primaryContact = contactsByAccount.get(opp.AccountId).Contacts;
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = primaryContact.Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        Database.update(oppMap.values(), accessLevel.USER_MODE);
    }
}