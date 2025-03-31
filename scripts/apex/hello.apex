

        Integer numberOfOpps = 5;
        for (Integer i = 0; i < numberOfOpps; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today()
            );
            insert opp;
        }

// OpportunityHelper.setType(newOpps);