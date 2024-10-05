import ioffice.alerts.*;
import tests.utils.*;

/**
 * @docs_abstract
 * Abstract Alert Tests: tests that alert instantiation doesn't error out
 * and that getAlertType doesn't error.  Loops over test data specified in
 * concrete implementations via getSpecs() to determine if the given student
 * is on the alert at the specified level or not.
 */
component extends="testbox.system.BaseSpec" {

	final THREATLEVEL_NONE = -1;
	final THREATLEVEL_LOW = 5;
	final THREATLEVEL_GUARDED = 4;
	final THREATLEVEL_ELEVATED = 3;
	final THREATLEVEL_HIGH = 2;
	final THREATLEVEL_SEVERE = 1;

	final TEST_ALERT_GROUP = "testonly";

	function beforeAll() {
		addMatchers(new AlertMatchers());
	}

	function run(testResults, testBox) {
		var dataHandler = new DataHandler();
		dataHandler.setupTestAlertGroup();

		describe("#getServiceID()# Tests", () => {
			given("nothing", () => {
				when("I instantiate the component", () => {
					then("the result should be a class that implements AbstractAlertService and has the right service id", () => {
						var alert = getAlertService();
						expect(alert).toBeInstanceOf("AbstractAlertService");
						expect(alert.getImplementedServiceID()).toBe(getServiceID());
					});
				});
			});

			given("an alert", () => {
				when("I get the AlertType", () => {
					then("the result should be an AlertType", () => {
						var alert = getAlertService();
						expect(alert.getAlertType()).toBeInstanceOf("AlertType");
					});
				});
			});

			for( var testData in getSpecs() ) {
				given(testData.given, () => {
					when("I run the alert", () => {
						aroundEach(dataHandler.isolate(), testData);

						var expectedResult = (testData.level == THREATLEVEL_NONE)
							? "the student should not be on the alert."
							: "the student should be on the alert at #getThreatLevelName(testData.level)#.";
						then(
							then: expectedResult,
							body: (data) => {
								data.idnumber = setupData(data);
								var debugFlag = data.keyExists("debug") ? data.debug : false;

								var startTime = Now();

								var alert = getAlertService();
								var alertXML = alert.getAlertsByIndividual(data.idnumber, debugFlag);

								if( debugFlag ) {
									debug(dataHandler.getDebugLogs(startTime));
								}

								if( data.level != THREATLEVEL_NONE ) {
									expect(alertXML).toHaveRecordsAtLevel(data.level);
									if ( data.keyExists("message") ) {
										expect(alertXML).toHaveMessage(data.message);
									}
								}
								else {
									expect(alertXML).notToHaveRecords();
								}

								for( var level=THREATLEVEL_LOW; level >= THREATLEVEL_SEVERE; level-- ) {
									var startTime = Now();

									alertXML = '<dataset type="Alert">' & alert.getAlertsByThreatLevel(level, debugFlag) & '</dataset>';

									if( debugFlag ) {
										debug(dataHandler.getDebugLogs(startTime));
									}

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
							},
							skip: testData.keyExists("skip") ? testData.skip : false
						);
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
	 * @docs_abstract
	 * The alert service id under test
	 */
	private string function getServiceID() {
		return "NullAlertService";
	}

	/**
	 * @docs_abstract
	 * the test cases. This is an array of structs. The structs must include "given"
	 * and "level" keys. The "given" key is a string that describes the data to be prepped
	 * for this test case. The "level" key specified which level of the alert the record is
	 * expected be on. "message" is an optional key for specifying an expected alert message.
	 * "debug" is an optional boolean key. When set to "true," it will output the SQL and results
	 * returned from running the alert and any errors logged to IOfficeLog to the test report's
	 * debug stream.
	 */
	private struct[] function getSpecs() {
		return ["struct"][];
	}

	/**
	 * @docs_abstract
	 * Sets up the data to test the alert
	 * @return the idnumber of the student being prepped.
	 */
	private numeric function setupData(required struct testData) {}

	private AbstractAlertService function getAlertService() {
		return new AlertServicesList().getAlertService(getServiceID(), TEST_ALERT_GROUP);
	}
}