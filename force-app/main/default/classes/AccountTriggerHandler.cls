/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-27-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AccountTriggerHandler extends TriggerHandler {
    private Map<Id, Account> newAccMap;
    private Map<Id, Account> oldAccMap;
    private List<Account> newAccs;
    private List<Account> oldAccs;

    public AccountTriggerHandler() {
        System.debug('OpportunityTrigger:::' + Trigger.operationType);
        this.newAccMap = (Map<Id, Account>) Trigger.newMap;
        this.oldAccMap = (Map<Id, Account>) Trigger.oldMap;
        this.newAccs = (List<Account>) Trigger.new;
        this.oldAccs = (List<Account>) Trigger.old;
    }

    public override void beforeInsert() {
        AccountHelper.setTypeProspect(newAccs);
        AccountHelper.addressCopy(newAccs);
        AccountHelper.setRating(newAccs);
    }

    public override void afterInsert() {
        AccountHelper.defaultContact(newAccs);
    }
}