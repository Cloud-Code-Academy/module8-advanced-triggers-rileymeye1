/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-27-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    private Map<Id, Opportunity> newOppMap;
    private Map<Id, Opportunity> oldOppMap;
    private List<Opportunity> newOpps;
    private List<Opportunity> oldOpps;
    
    public OpportunityTriggerHandler() {
        System.debug('OpportunityTrigger:::' + Trigger.operationType);
        this.newOppMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldOppMap = (Map<Id, Opportunity>) Trigger.oldMap;
        this.newOpps = (List<Opportunity>) Trigger.new;
        this.oldOpps = (List<Opportunity>) Trigger.old;
    }

    public override void beforeInsert() {
        OpportunityHelper.setDefualtType(newOpps);
    }

    public override void beforeUpdate() {
        OpportunityHelper.validateAmount(newOpps);
        OpportunityHelper.setPrimaryContact(newOpps);
        OpportunityHelper.appendStageChanges(newOpps, oldOppMap);
    }

    public override void beforeDelete() {
        OpportunityHelper.preventOppDeletion(oldOpps);
    }

    public override void afterInsert() {
        OpportunityHelper.createNewTask(newOpps);
    }

    public override void afterDelete() {
        OpportunityHelper.notifyOwnersOpportunityDeleted(oldOpps);
    }

    public override void afterUndelete() {
        OpportunityHelper.assignPrimaryContact(newOppMap);
    }
}