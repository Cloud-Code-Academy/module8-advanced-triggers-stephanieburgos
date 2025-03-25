public with sharing class AccountTriggerHandler extends TriggerHandler {
    
    private List<Account> newAccounts;

    public AccountTriggerHandler() {
        this.newAccounts = (List<Account>)Trigger.new;
    }

    public override void beforeInsert() {
        AccountHelper.setTypeProspect(this.newAccounts);
        AccountHelper.addressCopy(this.newAccounts);
        AccountHelper.setRating(this.newAccounts);
    }

    public override void afterInsert() {
        AccountHelper.defaultContact(this.newAccounts);
    }
}