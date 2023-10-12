/**
 * @deprecated: Use BaseDataHandler, ConfigDataHandler, or IntlDataHandler as appropriate
 */
component {

	final TEST_CAMPUS_CODE = "TOC";
	final TEST_UID = "TEST";
	final TEST_TERM_CODE = "test";

	/**
	 * @deprecated Use new BaseDataHandler().isolate
	 * 
	 * returns a function for use in aroundEach, that wraps a test in
	 * a transaction that is rolled back at the end.
	 *
	 * @preSpec A function to run after the start of the transaction, but before the actual test - for example, to prep the same data for every test
	 */
	public any function isolate(any preSpec="") {
		return new BaseDataHandler().isolate(preSpec);
	}

	/**
	 * @deprecated Use new ConfigDataHandler().getF1OrgCode
	 * 
	 * This is just a getter function for F1 org code.
	 * @return the F1 SEVIS Organization code
	 */
	public string function getF1OrgCode() {
		return new ConfigDataHandler().getF1OrgCode();
	}

	/**
	 * @deprecated Use new ConfigDataHandler().getJ1OrgCode
	 * 
	 * This is just a getter function for J1 org code.
	 * @return the J1 SEVIS Organization code
	 */
	public string function getJ1OrgCode() {
		return new ConfigDataHandler().getJ1OrgCode();
	}

	/**
	 * @deprecated Use new IntlDataHandler().getJ1OrgCode
	 * 
	 * This is just a getter function for the university id.
	 * @return the hard-coded university id
	 */
	public string function getUID() {
		return new IntlDataHandler().getUID();
	}

	/**
	 * @deprecated Use new ConfigDataHandler().getCampus
	 * 
	 * This is just a getter function for the campus.
	 * @return the hard-coded campus
	 */
	public string function getCampus() {
		return new ConfigDataHandler().getCampus();
	}

	/**
	 * @deprecated Use new ConfigDataHandler().getCampusDescription
	 * 
	 * This is just a getter function for the campus name.
	 * @return the hard-coded campus description
	 */
	public string function getCampusDescription() {
		return new ConfigDataHandler().getCampusDescription();
	}

	/**
	 * @deprecated Use new ConfigDataHandler().getAlertGroup
	 * 
	 * This is just a getter function for alertGroup.
	 * @return the hard-coded alertGroup
	 */
	public string function getAlertGroup() {
		return new ConfigDataHandler().getAlertGroup();
	}

	/**
	 * @deprecated use aroundeach and new BaseDataHandler().isolate instead.
	 * backs up the contents of the listed tables before the test runs
	 * optionally wipes tables as well
	 */
	public void function resetTables(required string tableList, boolean wipe = false) {
		QueryExecute("IF( @@TRANCOUNT = 0 ) BEGIN TRANSACTION;");
		if( wipe ) {
			for( var table in tableList ) {
				QueryExecute("DELETE FROM " & Trim(table));
			}
		}
	}

	/**
	 * @deprecated use aroundeach and new BaseDataHandler().isolate instead
	 * rolls back the transaction started in resetTables
	 */
	public void function restoreTables() {
		QueryExecute("IF( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION;");
	}

	/**
	 * @deprecated Use new ConfigDataHandler().setupTestCampus
	 * 
	 * This sets up the test campus information
	 * and information in mapCampusApplicationArea
	 * needed to run the tests.
	 */
	public void function setupTestCampus() {
		new ConfigDataHandler().setupTestCampus();
	}

	/**
	 * @deprecated Use new ConfigDataHandler().setupTestAlertGroup
	 * 
	 * This sets up alert group information into
	 * configAlertCampus, and configAlertOrgCode
	 * for both F-1s and J-1s.
	 */
	public void function setupTestAlertGroup() {
		new ConfigDataHandler().setupTestAlertGroup();
	}

	/**
	 * @deprecated Use new IntlDataHandler().createAlertOverride
	 * 
	 * This sets up an alert override,
	 * using the given idnumber, and alert service id.
	 * @return the generated recnum.
	 */
	public numeric function createAlertOverride(
		required numeric idnumber,
		required string alertService,
		boolean forever=false,
		numeric endDateOffset=0
	) {
		return new IntlDataHandler().createAlertOverride(idnumber, alertService, forever, endDateOffset);
	}

	/**
	 * @deprecated Use new IntlDataHandler().createRecord
	 * 
	 * Creates a new student with the given university id (defaults to "TEST"),
	 * 'TOC' as campus, and it can take immigrationStatus as an
	 * argument, but if not given the argument it will default to
	 * 'F-1'.
	 * @return the new idnumber
	 */
	public numeric function createRecord(
		string immigrationStatus="F-1", 
		string orgCode="",
		string universityid=TEST_UID
	) {
		return new IntlDataHandler().createRecord(immigrationStatus, orgCode, universityid);
	}


	/**
	 * @deprecated Use ConfigDataHandler.createTerm
	 * 
	 * make sure that a term is configured
	 *
	 * @termCode The code to use (defaults to "test")
	 * @startOffset the number of days until the term start (default is -30 - the term starts a month ago)
	 * @endOffset the number of days in the term (default is 120 - the term ends is 4 months long)
	 */
	public string function createTerm(
		string termCode=TEST_TERM_CODE, 
		string campus=TEST_CAMPUS_CODE, 
		numeric startOffset=-30, 
		numeric length=120
	) {
		return new ConfigDataHandler().createTerm(termCode, campus, startOffset, length);
	}

	public void function setOptional(required string term) {
		new ConfigDataHandler().setOptional(term);
	}

	/**
	 * @deprecated Use ConfigDataHandler.createCurrentTerm
	 * 
	 * configures a row for the term at the "TOC" campus
	 * to ensure that this is a current term.
	 * @return the term code
	 */
	public string function createCurrentTerm(
		string term=TEST_TERM_CODE, 
		string campus=TEST_CAMPUS_CODE
	) {
		return new ConfigDataHandler().createCurrentTerm(term, campus);
	}

	/**
	 * @deprecated Use new IntlDataHandler().createAdmissionRecord
	 * 
	 * configures an admission record for a future term
	 *
	 * @idnumber the student to add the admission record to
	 */
	public void function createAdmissionRecord(
		required numeric idnumber,
		string admitStatus="AC",
		numeric startOffset=-30
	) {
		new IntlDataHandler().createAdmissionRecord(idnumber, admitStatus, startOffset);
	}

	/**
	 * @deprecated Use new IntlDataHandler().createEnrollment
	 * 
	 * Creates an enrollment row in jbStudentTerm,
	 * using the given idnumber, and term code.
	 * It defaults the career type to UGRD,
	 * and the academic level to 30.
	 *
	 * It also adds a row in iuieCourses,
	 * using the given idnumber and corresponding university id
	 * It defaults the following:
	 * ACAD_UNT_TKN_NBR = 3,
	 * STU_ENRL_STAT_CD = 'E'
	 */
	public void function createEnrollment(
		required numeric idnumber,
		required string term,
		numeric credits=15.0,
		string career="UGRD"
	) {
		new IntlDataHandler().createEnrollment(idnumber, term, credits, career);
	}

	/**
	 * @deprecated Use new IntlDataHandler().createAcademicProgram
	 * 
	 * Creates a new academic program with the Program status defaulting to Active.
	 * @return the recnum of the new row.
	 */
	public numeric function createAcademicProgram(
		required numeric idnumber,
		string academicProgramStatus="AC",
		string career="UGRD"
	) {
		return new IntlDataHander().createAcademicProgram(idnumber, academicProgramStatus, career);
	}

	/**
	 * @deprecated Use new IntlDataHandler().createI20Record
	 * 
	 * Creates core I-20  for the student, updating jbInternational to match
	 * Sets program to be active by default, with start -1 month, end +1 month from now
	 * Sets currentSessionStart -1 month, currentSessionEnd + 1 month, nextSessionStart +2 months from now
	 * @return the sevisid
	 */
	public string function createI20Record(
		required numeric idnumber,
		string sevisStatus="A",
		string eduLevel="04",
		string primary="00.0000"
	) {
		return new IntlDataHandler().createI20Record(idnumber, sevisStatus, eduLevel, primary);
	}

	/**
	 * @deprecated Use new IntlDataHandler().createSEVISI20OPT
	 * 
	 * Creates an OPT record for the student,.
	 * Sets the status to be approved by default,
	 * and the complettion type to STEM, or 03.
	 * @return the generated recnum.
	 */
	public numeric function createSEVISI20OPT(
		required numeric idnumber,
		required string sevisid,
		string completionType="03"
	) {
		return new IntlDataHandler().createSEVISI20OPT(idnumber, sevisid, completionType);
	}

	/**
	 * @deprecated Use new IntlDataHandler().createSEVISI20CPT
	 * 
	 * Creates an CPT record for the student.
	 * Sets the status to be approved by default.
	 * @return the generated recnum.
	 */
	public void function createSEVISI20CPT(
		required numeric idnumber,
		required string sevisid
	) {
		new IntlDataHandler().createSEVISI20CPT(idnumber, sevisid);
	}

	/**
	 * @deprecated Use new IntlDataHandler().createDS2019Record
	 * 
	 * Creates core DS-2019 for the student, updating jbInternational to match
	 * Sets program to be active by default and student, with start -1 month, end +1 month from now
	 * @return the sevisid
	 */
	public string function createDS2019Record(
		required numeric idnumber,
		string sevisStatus="A",
		string categoryCode="1C",
		string subjectField="00.0000"
	) {
		return new IntlDataHandler().createDS2019Record(idnumber, sevisStatus, categoryCode, subjectField);
	}

	/**
	 * @deprecated Use new IntlDataHandler().createH1BRecord
	 * 
	 * Creates core H1B for the student, updating jbInternational to match
	 * Sets LCA/H1B to be active by default, with start -1 month, end +1 month from now
	 * @return the LCA Number
	 */
	public string function createH1BRecord(
		required numeric idnumber, 
		string status="A"
	) {
		return new IntlDataHandler().createH1BRecord(idnumber, status);
	}

	/**
	 * @deprecated Use new IntlDataHandler().debug
	 * 
	 * Outputs a struct of the data for debugging
	 * If an idnumber exists in the table/view that it will filter on the given idnumber.
	 * If the table does not have an idnumber column then it will list all data in the table.
	 *
	 * @idnumber the record to filter on
	 * @tables an array of tables and views to examine
	 */
	public struct function debug(required numeric idnumber, string[] tables) {
		return new BaseDataHandler().debug(idnumber, tables);
	}

	/**
	 * @deprecated Use new BaseDataHandler().getDebugLogs
	 * 
	 * Lookup debug logs from when the test was running
	 *
	 * @startTime the time that the test started
	 */
	public array function getDebugLogs(required date startTime) {
		return new BaseDataHandler().getDebugLogs(startTime);
	}
}
 