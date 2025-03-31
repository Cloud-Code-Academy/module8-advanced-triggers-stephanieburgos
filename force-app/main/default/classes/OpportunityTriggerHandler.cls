public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    private List<Opportunity> newOppList;
    private Map<Id, Opportunity> newOppMap;
    private List<Opportunity> oldOppList;
    private Map<Id, Opportunity> oldOppMap;
    
    public OpportunityTriggerHandler() {
        this.newOppList = (List<Opportunity>) Trigger.new;
        this.newOppMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldOppList = (List<Opportunity>) Trigger.old;
        this.oldOppMap = (Map<Id, Opportunity>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        System.debug('NEWOPPLIST::: ' + newOppList);
        OpportunityHelper.setType(newOppList);
    }

    public override void beforeUpdate() {
        OpportunityHelper.amountValidation(newOppList);

        OpportunityHelper.setPrimaryContact(newOppList);
    }

    public override void beforeDelete() {
        OpportunityHelper.deleteCloseWonOpportunity(oldOppList);
    }
    
    public override void afterInsert() {
        OpportunityHelper.insertTask(newOppList);
    }

    public override void afterUpdate() {
        OpportunityHelper.updateDescriptionFromStage(newOppList, oldOppMap);     
    }

    public override void afterDelete() {
        OpportunityHelper.notifyOwnersOpportunityDeleted(oldOppList);
    }

    public override void afterUndelete() {
        OpportunityHelper.assignPrimaryContact(newOppMap);
    }
}