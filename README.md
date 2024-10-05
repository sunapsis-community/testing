# testing
Tools for building automated tests for custom components. These are built on the TextBox framework from Ortus Solutions.

**Under no circumstances should tests ever be deployed to a production server.**

## Install
To add testing to your test or dev server, copy the `testbox` and `tests` directories to your sunapsis webroot.

## Run
You can run the tests by visting `<site>/tests`.

# What's Here
There are no actual tests included in this package.  `tests.ioffice.alerts.AbstractAlertBDDTest` is techinically a test, but it doesn't actually do anything.
You can test alerts by extending this class. You will need to implement 3 methods: `getServiceID`, `getSpecs`, and `setupData`.

### getServiceID
This returns the alert service id of the alert service under test (ex. `OtherTempIDAlertService`)

### getSpecs
This returns an array of test specifications.  Each test spec is a struct which contains at least 2 keys: `given` and `level`.  `given` is
a string that just describes the data that is being set up (ex. "a student with a university id that begins with TEMP"). `level` is the
alert level that this student is expected to be on when the test runs successfully. The abstract defines the following constants to improve
your test legibility:
* `THERATLEVEL_NONE`: the student is not on the alert
* `THREATLEVEL_LOW`: the student is on the alert at Low (Green)
* `THREATLEVEL_GUARDED`: the student is on the alert at Guarded (Blue)
* `THREATLEVEL_ELEVATED`: the student is on the alert at Elevated (Yellow)
* `THREATLEVEL_HIGH`: the student is on the alert at High (Orange)
* `THREATLEVEL_SEVERE`: the student is on the alert at Severe (Red)

`message` is an optional key for specifying an expected alert message.
`debug` is an optional boolean key. When set to `true`, it will output any errors logged to IOfficeLog and, starting in
sunapsis v4.1.23/v4.2.14, the SQL and results returned from running the alert to the test report's debug stream.

You can define any other keys you wish to assist with prepping data for your test. These can be referenced in the `setupData` function
described below.

### setupData
This function takes one of the test specs defined in `getSpecs` and returns the idnumber of the student being tested.  Any database queries
run during the test are wrapped in a single transaction and rolled back at the end of the test so the database will automatically be in the
exact same state before and after the test run.

You can use the `test.utils.DataHandler` utility class to create a record, and then add data to it.  Anything that's not covered by the
`DataHandler` can be added via a custom database query.

When a spec is run, it runs several tests:
1. the alert can be instantiated correctly -- this will catch any syntax errors that prevent your alert from being created correctly
2. `getAlertType` runs correctly
3. run the alert in student record mode
  * make sure the student is on the alert at the expected level when you open up the student record
  * if a `message` iss specified in the spec, ensure that it matches the expected value.
4. run the alert for each level in Alert Management mode
  * make sure the student is on the alert at the expected level
  * make sure the student is not on the alert at any other levels
  * if a `message` is specified in the spec, ensure that it matches the expected value

