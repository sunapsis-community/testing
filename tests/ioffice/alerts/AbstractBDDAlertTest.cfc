import ioffice.alerts.*;
import testbox.tests.utils.*;


/**
 * Abstract Alert Tests
 */
component extends="testbox.system.BaseSpec" {

    variables.THREATLEVEL_NONE = -1;
    variables.THREATLEVEL_LOW = 5;
    variables.THREATLEVEL_GUARDED = 4;
    variables.THREATLEVEL_ELEVATED = 3;
    variables.THREATLEVEL_HIGH = 2;
    variables.THREATLEVEL_SEVERE = 1;

    variables.TEST_ALERT_GROUP = 'testonly';

    function beforeAll() {
		addMatchers(new AlertMatchers());
	}

	function run(testResults, testBox) {
        var dataHandler = new DataHandler();
        dataHandler.setupTestAlertGroup();

        describe("#getServiceID()# Tests", function() {

            given("nothing", function() {
                when("I instantiate the component", function() {
                    then("the result should be a class that implements AbstractAlertService and has the right service id", function() {
                        var alert = getAlertService();
                        expect(alert).toBeInstanceOf("ioffice.alerts.AbstractAlertService");
                        expect(alert.getImplementedServiceID()).toBe(getServiceID());
                    });
                });
            });

            for( var testData in getSpecs() ) {
                given(testData.given, function() {
                    when("I run the alert", function() {
                        aroundEach(dataHandler.isolate(), testData);

                        var expectedResult = (testData.level == THREATLEVEL_NONE)
                            ? "the student should not be on the alert."
                            : "the student should be on the alert at #getThreatLevelName(testData.level)#.";
                        then(expectedResult, function(data) {
                            data.idnumber = setupData(data);

                            var alert = getAlertService();
                            var alertXML = alert.getAlertsByIndividual(data.idnumber);

                            if( data.level != THREATLEVEL_NONE ) {
                                expect(alertXML).toHaveRecordsAtLevel(data.level);
                                if ( data.keyExists("message") ) {
                                    expect(alertXML).toHaveMessage(data.message);
                                }
                            }
                            else {
                                expect(alertXML).notToHaveRecords();
                            }

                            for ( var level=THREATLEVEL_LOW; level >= THREATLEVEL_SEVERE; level-- ) {
                                alertXML = '<dataset type="Alert">' & alert.getAlertsByThreatLevel(level) & '</dataset>';
                                if( level == data.level ) {
                                    expect(alertXML).toHaveRecords();
                                    if ( data.keyExists("message") ) {
                                        expect(alertXML).toHaveMessage(data.message);
                                    }
                                }
                                else {
                                    expect(alertXML).notToHaveRecords();
                                }
                            }
                        });
                    });
                });
            }
        });

    }

	private string function getThreatLevelName(required numeric threatLevel) {
		switch( threatLevel ) {
			case 1:
				return "Severe (red)";
			case 2:
				return "High (orange)";
			case 3:
				return "Elevated (yellow)";
			case 4:
				return "Guarded (blue)";
			case 5:
				return "Low (green)";
			default:
				return "Unknown";
		}
	}

    /**
     * @abstract
     */
    private string function getServiceID() {
        return "NullAlertService";
    }

    /**
     * @abstract
     */
    private array function getSpecs() {
        return [];
    }

    /**
     * @abstract
     * Sets up the data to test the alert
     * @return the idnumber of the student being prepped.
     */
    private numeric function setupData(required struct testData) {}

    private AbstractAlertService function getAlertService() {
        return new AlertServicesList().getAlertService(getServiceID(), TEST_ALERT_GROUP);
    }
}