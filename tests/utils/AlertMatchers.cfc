component {

    boolean function toHaveRecords(required expectation, args={}) {
        try {
            var records = new Parser().parseDataLayer(expectation.actual);
            expectation.message = args.keyExists("message") ? args.message : "The alert has [#records.len()#] record(s).";
            if( expectation.isNot ) {
                return records.len() == 0;
            }
            return records.len() > 0;
        }
        catch( any exception ) {
            fail(exception.message);
        }
    }

    boolean function toHaveRecordsAtLevel(required expectation, args={}) {
        try {
            var parser = new Parser();
            var records = parser.parseDataLayer(expectation.actual);
            var expectedLevel = args[1];
            var actualLevel = "";

            if( records.len() > 0 ) {
                actualLevel = parser.getValue(records[1], "threatLevel");
                expectation.message = "The alerts has [#records.len()#] record(s) at level [#actualLevel#].";
            }
            else {
                expectation.message = args.keyExists("message") ? args.message : "The alert has [#records.len()#] record(s) at level [#expectedLevel#].";
            }
            if( expectation.isNot ) {
                return actualLevel != expectedLevel;
            }
            return actualLevel == expectedLevel;
        }
        catch( any exception ) {
            fail(exception.message);
        }
    }

}
