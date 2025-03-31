public with sharing class OpportunityHelper {
    
    public static void amountValidation (List<Opportunity> newOpps) {
        for(Opportunity opp : newOpps){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    public static void deleteCloseWonOpportunity (List<Opportunity> oldOpps) {
        //Account related to the opportunities 
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :oldOpps)]);
        for(Opportunity opp : oldOpps){
            if (opp.isClosed) {
                opp.addError('Cannot delete closed opportunity');
            } else if (opp.StageName == 'Closed Won'){
                if(accounts.get(opp.AccountId).Industry == 'Banking'){
                    opp.addError('Cannot delete closed opportunity');
                }    
            }    
        }
    }

    public static void setType(List<Opportunity> newOpps) {
        for (Opportunity opp : newOpps) {
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }    
        }
    }

    public static void setPrimaryContact(List<Opportunity> newOpps) {
        //Get contacts related to the opportunity account
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : newOpps){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
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

    public static void insertTask(List<Opportunity> newOpps) {
        List<Task> tasksToInsert = new List<Task>();
            for (Opportunity opp : newOpps){
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3); 
                tasksToInsert.add(tsk);
            }
            Database.insert(tasksToInsert);
    }

    public static void updateDescriptionFromStage (List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Opportunity opp : newOppList){
            Opportunity oldOpp = oldOppMap.get(opp.Id); 
            if (opp.StageName != null && !opp.StageName.equals(oldOpp.StageName)){
                Opportunity oppToUpdate = opp.clone(false, true);
                oppToUpdate.Id = opp.Id;
                oppToUpdate.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                oppsToUpdate.add(oppToUpdate);
            }
                            
        }
        Database.update(oppsToUpdate);
    }

    public static void notifyOwnersOpportunityDeleted (List<Opportunity> opps) {
        Set<Id> userIdsFromOpp = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.OwnerId != null) {
                userIdsFromOpp.add(opp.OwnerId);
            }
        }

        if (!userIdsFromOpp.isEmpty()) {
            Map<Id, User> userIdToUserMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :userIdsFromOpp]);
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            for (Opportunity opp : opps) { 
                if (opp.OwnerId != null && userIdToUserMap.containsKey(opp.OwnerId)) {
                    User owner = userIdToUserMap.get(opp.OwnerId);
                    if (owner.Email != null) {
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        String[] toAddresses = new String[] { owner.Email };
                        mail.setToAddresses(toAddresses);
                        mail.setSubject('Opportunity Deleted : ' + opp.Name);
                        mail.setPlainTextBody('Your Opportunity: ' + opp.Name + ' has been deleted.');
                        mails.add(mail);    
                    } 
                } 
            }
            
            try {
                if (!mails.isEmpty()) {
                    Messaging.sendEmail(mails);
                }
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
            }
        } 
    }

    public static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
        Set<Id> oppAccountIds = new Set<Id>();
        for (Opportunity opp : oppNewMap.values()){
            oppAccountIds.add(opp.AccountId);
        }

        Map<Id, Account> acctIdToAcctMap = new Map<Id, Account>(
            [SELECT Id, Name,
                (SELECT Id FROM Contacts WHERE Title = 'VP Sales') 
            FROM Account 
            WHERE Id IN :oppAccountIds]
        );
        
        Map<Id, Opportunity> oppIdToOppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : oppNewMap.values()){            
            if (opp.Primary_Contact__c == null && !acctIdToAcctMap.get(opp.AccountId).Contacts.isEmpty()){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = acctIdToAcctMap.get(opp.AccountId).Contacts[0].Id;
                oppIdToOppMap.put(opp.Id, oppToUpdate);
            }
        }
        Database.update(oppIdToOppMap.values());
    }
}