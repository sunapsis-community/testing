component {

	variables.TEST_CAMPUS_CODE = 'TOC';
	variables.TEST_CAMPUS_DESCRIPTION = 'Test Only Campus';
	variables.TEST_ALERT_GROUP = 'testonly';
	variables.F1_ORG_CODE = 'SEA214F28700003';
	variables.J1_ORG_CODE = 'P-1-00104';
	variables.TEST_UID = 'TEST';
	variables.TEST_TERM_CODE = 'test';

	public DataHandler function init() {
		return this;
	}

	/**
	 * returns a function for use in aroundEach, that wraps a test in
	 * a transaction that is rolled back at the end.
	 *
	 * @preSpec A function to run after the start of the transaction, but before the actual test - for example, to prep the same data for every test
	 */
	public any function isolate(any preSpec="") {
		return function(required struct spec, required struct suite) {
			if( ( !IsClosure(preSpec) && !IsCustomFunction( preSpec ))) {
				preSpec = function() {};
			}

			transaction {
				preSpec();
				spec.body(data: suite.aroundEachData);
				transaction action="rollback";
			}
		};
	}

	/**
	 * This is just a getter function for F1 org code.
	 * @return the F1 SEVIS Organization code
	 */
	public string function getF1OrgCode(){
		return F1_ORG_CODE;
	}

	/**
	 * This is just a getter function for J1 org code.
	 * @return the J1 SEVIS Organization code
	 */
	public string function getJ1OrgCode(){
		return J1_ORG_CODE;
	}

	/**
	 * This is just a getter function for the university id.
	 * @return the hard-coded university id
	 */
	public string function getUID(){
		return TEST_UID;
	}

	/**
	 * This is just a getter function for the campus.
	 * @return the hard-coded campus
	 */
	public string function getCampus(){
		return TEST_CAMPUS_CODE;
	}

	/**
	 * This is just a getter function for alertGroup.
	 * @return the hard-coded alertGroup
	 */
	public string function getAlertGroup(){
		return TEST_ALERT_GROUP;
	}

	/**
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

	public void function restoreTables() {
		QueryExecute("IF( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION;");
	}

	/**
	 * This sets up the test campus information
	 * and information in mapCampusApplicationArea
	 * needed to run the tests.
	 */
	private void function setupTestCampus() {
		QueryExecute(
			"MERGE dbo.codeCampus
			USING (
				SELECT
					:campusCode AS code,
					:campusDescription AS description,
					:campusCode AS shortCode
			) AS source
			ON source.code = codeCampus.code
			WHEN NOT MATCHED
			THEN INSERT (
				code,
				description,
				shortCode
			)
			VALUES (
				source.code,
				source.description,
				source.shortCode
			);",
			{
				campusCode: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE},
				campusDescription: {cfsqltype: "nvarchar", value: TEST_CAMPUS_DESCRIPTION}
			}
		);

		QueryExecute(
			"MERGE INTO dbo.mapCampusApplicationArea
			USING (
				SELECT :campusCode AS campus
			) AS source
			ON source.campus = mapCampusApplicationArea.campus
			WHEN NOT MATCHED
				THEN INSERT (
						campus,
						f1Campus,
						j1StudentCampus,
						j1ScholarCampus,
						h1bCampus,
						prCampus,
						otherCampus,
						studentOpenDoors
					)
					VALUES (
						source.campus,
						source.campus,
						source.campus,
						source.campus,
						source.campus,
						source.campus,
						source.campus,
						source.campus
					);",
			{
				campusCode: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE}
			}
		);

		QueryExecute(
			"MERGE dbo.codeSEVISOrg
			USING (
				SELECT :f1orgcode AS orgCode
			) AS source
			ON source.orgCode = codeSEVISOrg.orgCode
			WHEN MATCHED
				THEN UPDATE SET campusList += :campusCode + ','
			WHEN NOT MATCHED
				THEN INSERT (
						 orgCode
						 , visaType
						 , description
						 , fullDescription
						 , PDSORO
						 , campus
						 , campusList
					 )
					 VALUES (
						 source.orgCode
						 , 'F-1'
						 , 'Test SEVIS Org'
						 , 'Test SEVIS Organization'
						 , 'tpdso-0000'
						 , :campusCode
						 , :campusCode + ','
					 );", 
			{
				campusCode: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE},
				f1orgcode: {cfsqltype: "nvarchar", value: F1_ORG_CODE}
			}
		);

		QueryExecute(
			"MERGE dbo.codeSEVISOrg
			USING (
				SELECT :j1orgcode AS orgCode
			) AS source
			ON source.orgCode = codeSEVISOrg.orgCode
			WHEN MATCHED
				THEN UPDATE SET campusList += :campusCode + ','
			WHEN NOT MATCHED
				THEN INSERT (
						 orgCode
						 , visaType
						 , description
						 , fullDescription
						 , PDSORO
						 , campus
						 , campusList
					 )
					 VALUES (
						 source.orgCode
						 , 'J-1'
						 , 'Test SEVIS Org'
						 , 'Test SEVIS Organization'
						 , 'tpdso-0000'
						 , :campusCode
						 , :campusCode + ','
					 );", 
			{
				campusCode: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE},
				j1orgcode: {cfsqltype: "nvarchar", value: J1_ORG_CODE}
			}
		);
	}

	/**
	 * This sets up alert group information into
	 * configAlertCampus, and configAlertOrgCode
	 * for both F-1s and J-1s.
	 */
	public void function setupTestAlertGroup() {
		QueryExecute(
			"MERGE dbo.configAlertCampus
			USING (
				SELECT
					:alertGroup AS alertGroup,
					:campus AS campus
			) AS source
			ON source.alertGroup = configAlertCampus.alertGroup
				AND source.campus = configAlertCampus.campus
			WHEN NOT MATCHED
				THEN INSERT (
						alertGroup,
						campus
					)
					VALUES (
						source.alertGroup,
						source.campus
					);",
			{
				alertGroup: {cfsqltype: "nvarchar", value: TEST_ALERT_GROUP},
				campus: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE}
			}
		);

		QueryExecute(
			"MERGE dbo.configAlertOrgCode
			USING (
				SELECT
					:alertGroup AS alertGroup,
					:orgCode AS orgCode
				) AS source
			ON source.alertGroup = configAlertOrgCode.alertGroup
			AND source.orgCode = configAlertOrgCode.orgCode
			WHEN NOT MATCHED
			THEN INSERT (
				alertGroup,
				orgCode
				)
			VALUES (
				source.alertGroup,
				source.orgCode
			);",
			{
				alertGroup: {cfsqltype: "nvarchar", value: TEST_ALERT_GROUP},
				orgCode: {cfsqltype: "nvarchar", value: F1_ORG_CODE}
			}
		);

		QueryExecute(
			"MERGE dbo.configAlertOrgCode
			USING (
				SELECT
					:alertGroup AS alertGroup,
					:orgCode AS orgCode
				) AS source
			ON source.alertGroup = configAlertOrgCode.alertGroup
			AND source.orgCode = configAlertOrgCode.orgCode
			WHEN NOT MATCHED
			THEN INSERT (
				alertGroup,
				orgCode
				)
			VALUES (
				source.alertGroup,
				source.orgCode
			);",
			{
				alertGroup: {cfsqltype: "nvarchar", value: TEST_ALERT_GROUP},
				orgCode: {cfsqltype: "nvarchar", value: J1_ORG_CODE}
			}
		);
	}

	/**
	 * This sets up and alert override, 
	 * using the given idnumber, and alert service id.
	 * @return the generated recnum.
	 */
	public numeric function createAlertOverride(
		required numeric idnumber, 
		required string alertService,
		numeric forever=0,
		numeric endDate=0
	) {
		QueryExecute(
			"INSERT INTO dbo.jbAlertsOverride (
    			idnumber,
    			serviceID,
    			semester,
    			username,
    			datestamp,
    			endDate,
    			forever
			)
			VALUES (   
				:idnumber,
    			:alertService,
    			NULL,
    			N'ioffice_admin',
    			CURRENT_TIMESTAMP,
    			DATEADD(DAY, :endDate, CURRENT_TIMESTAMP),
    			:forever
    		);",
            {
                idnumber: {cfsqltype: "integer", value: idnumber},
				alertService: {cfsqltype: "nvarchar", value: alertService},
				forever: {cfsqltype: "integer", value: forever},
				endDate: {cfsqltype: "integer", value: endDate}
			},
			{result: "local.result"}
		);
		
		return result.GENERATEDKEY;
	}

	/**
	 * Creates a new student with the given university id (defaults to "TEST"),
	 * 'TOC' as campus, and it can take immigrationStatus as an
	 * argument, but if not given the argument it will default to
	 * 'F-1'.
	 * @return the new idnumber
	 */
	public numeric function createRecord(
		string immigrationStatus='F-1',
		string orgCode = '',
		string universityID="TEST"
	) {
		// create a campus first
		setupTestCampus();
		
		QueryExecute(
			"INSERT INTO dbo.jbInternational ( 
				universityid
				, orgCode
				, campus
				, immigrationstatus
			) 
			VALUES ( 
				:uid
				, :orgCode
				, :campus
				, :immigrationStatus
			);",
			{
				uid: {cfsqltype: "nvarchar", value: universityID},
				orgCode: {cfsqltype: "nvarchar", value: F1_ORG_CODE},
				campus: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE},
				immigrationStatus: {cfsqltype: "nvarchar", value: immigrationStatus}
			},
			{result: "local.result"}
		);

		var idnumber = result.GENERATEDKEY;

		QueryExecute(
			"INSERT INTO dbo.jbInternationalBioExt ( idnumber ) VALUES ( :idnumber );",
			{ idnumber: {cfsqltype: "integer", value: idnumber} }
		);

		QueryExecute(
			"INSERT INTO dbo.jbCommunication ( idnumber ) VALUES ( :idnumber );",
			{ idnumber: {cfsqltype: "integer", value: idnumber} }
		);
		return idnumber;
	}

	/**
	 * make sure that a term is configured
	 *
	 * @termCode The code to use (defaults to "test")
	 * @startOffset the number of days until the term start (default is -30 - the term starts a month ago)
	 * @endOffset the number of days until the term end (default is 90 - the term ends in 3 months)
	 */
	public string function createTerm(string termCode="test", numeric startOffset=-30, numeric endOffset=90) {
		QueryExecute(
            "MERGE dbo.codeTermType
			USING (
				SELECT
					:term AS code,
					N'Test term type' AS description,
					1 AS required,
					1 AS sevis,
					1 AS opendoors
			) AS source
			ON source.code = codeTermType.code
			WHEN MATCHED
				THEN UPDATE SET
						 codeTermType.description = source.description,
						 codeTermType.required = source.required,
						 codeTermType.sevis = source.sevis,
						 codeTermType.opendoors = source.opendoors
			WHEN NOT MATCHED
				THEN INSERT (
						 code,
						 description,
						 required,
						 sevis,
						 opendoors
					 )
					 VALUES (
						 source.code,
						 source.description,
						 source.required,
						 source.sevis,
						 source.opendoors
					 );", 
			{
				term: {cfsqltype: "nvarchar", value: termCode}
			}
		);

		QueryExecute(
			"MERGE dbo.codeTerm
			USING (
				SELECT
					:code AS code,
					:code AS type,
					YEAR( CURRENT_TIMESTAMP ) AS year,
					N'' AS moreDescription,
					:code AS reportCode,
					1 AS showInIStart
			) AS source
			ON source.code = codeTerm.code
			WHEN MATCHED
				THEN UPDATE SET
						codeTerm.type = source.type,
						codeTerm.year = source.year,
						codeTerm.moreDescription = source.moreDescription,
						codeTerm.reportCode = source.reportCode,
						codeTerm.showInIStart = source.showInIStart
			WHEN NOT MATCHED
				THEN INSERT (
						code,
						type,
						year,
						moreDescription,
						reportCode,
						showInIStart
					)
					VALUES (
						source.code,
						source.type,
						source.year,
						source.moreDescription,
						source.reportCode,
						source.showInIStart
					);",
			{
				code: {cfsqltype: "nvarchar", value: termCode}
			}
		);

		QueryExecute(
            "MERGE dbo.configTerm
			USING (
				SELECT
					:code AS term,
					:campus AS campus,
					CAST(DATEADD( DAY, :startOffset, CURRENT_TIMESTAMP ) AS DATE) AS startDate,
					CAST(DATEADD( DAY, :endOffset, CURRENT_TIMESTAMP ) AS DATE) AS endDate
			) AS source
			ON source.term = configTerm.term
				AND source.campus = configTerm.campus
			WHEN MATCHED
				THEN UPDATE SET
						configTerm.startDate = source.startDate,
						configTerm.endDate = source.endDate
			WHEN NOT MATCHED
				THEN INSERT (
						term,
						campus,
						startDate,
						endDate
					)
					VALUES (
						source.term,
						source.campus,
						source.startDate,
						source.endDate
					);", 
			{
				code: {cfsqltype: "nvarchar", value: termCode},
				campus: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE},
				startOffset: {cfsqltype: "integer", value: startOffset},
				endOffset: {cfsqltype: "integer", value: endOffset}
			}
		);
		
		return termCode;
	}

	/**
	 * configures a row for the term at the "TOC" campus
	 * to ensure that this is a current term.
	 * @return the term code
	 */
	public string function createCurrentTerm() {
        return createTerm();
	}

	public void function createAdmissionRecord(required numeric idnumber, required string uid) {
		QueryExecute(
			"INSERT INTO dbo.iuieAdmissions (
				PRSN_UNIV_ID,
				APPL_PGM_STAT_CD,
				STU_ADMT_TERM_BEG_DT,
				STU_ADMT_TERM_END_DT,
				idnumber
			)
			VALUES (
				:uid,
				'AC',
				DATEADD( DAY, -30, CURRENT_TIMESTAMP ),
				DATEADD( DAY, 90, CURRENT_TIMESTAMP ),
				:idnumber
			);",
			{
				uid: {cfsqltype: "nvarchar", value: uid},
				idnumber: {cfsqltype: "integer", value: idnumber}
			}
		);
	}
	
	/**
	 * Creates an enrollment row in jbStudentTerm,
	 * using the given idnumber, and term code.
	 * It defaults the career type to UGRD,
	 * and the academic level to 30.
	 * 
	 * It also adds a row in iuieCourses,
	 * using the given idnumber, and the
	 * hard-coded university ID, 'TEST'.
	 * It defaults the following:
	 * ACAD_UNT_TKN_NBR = 3,
	 * STU_ENRL_STAT_CD = 'E',
	 * CLS_INSTRC_MODE_CD = 'DO', 
	 * CMP_LOC_CD = 'ON'.
	 */
	public void function createEnrollment(
		required numeric idnumber, 
		required string term, 
		numeric credits=15.0,
		string career='UGRD'
	) {
		QueryExecute(
			"INSERT INTO dbo.jbStudentTerm (
				idnumber,
				semester,
				campus,
				termStart,
				termEnd,
				credits,
				onlineCredits,
				status,
				academicCareer,
				academicLevel,
				primaryCIPMajor,
				visa,
				fullTimeOverride,
				newStudentFlag,
				censusMarker,
				substatus,
				distanceEducationOnly
			)
			VALUES	(
				:idnumber,
				:term,
				:campus,
				DATEADD(DAY, -30, CURRENT_TIMESTAMP),
				DATEADD(DAY, 90, CURRENT_TIMESTAMP),
				:credits,
				0.0,
				N'E',
				:career,
				:academicLevel,
				N'',
				N'',
				0,
				0,
				1,
				N'',
				0
			);",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				campus: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE},
				credits: {cfsqltype: "integer", value: credits},
				career: {cfsqltype: "nvarchar", value: career},
				academicLevel: {cfsqltype: "nvarchar", value: '30'},
				term: {cfsqltype: "nvarchar", value: term}
			}
		);
		
		

		QueryExecute(
			"INSERT INTO dbo.iuieCourses (
				PRSN_UNIV_ID,
				STU_ENRL_STAT_DT,
				ACAD_UNT_TKN_NBR,
				STU_ENRL_STAT_CD,
				STU_ENRL_STAT_REAS_CD,
				STU_ENRL_ADD_DT,
				STU_ENRL_DRP_DT,
				PPLSFT_ACAD_ORG_LVL_2_CD,
				CRS_SUBJ_CD,
				CRS_CATLG_NBR,
				CRS_SUBJ_DEPT_CD,
				ACAD_TERM_CD,
				idnumber,
				CRN_NBR,
				CRS_TITLE,
				CLS_KEY,
				CLS_NBR,
				CLS_SESN_CD,
				CLS_INSTRC_MODE_CD,
				CMP_LOC_CD
			)
			VALUES (
				:uid,
				GETDATE(),
				3,
				'E',
				'',
				GETDATE(),
				GETDATE(),
				'',
				'',
				'',
				'',
				'',
				:idnumber,
				'',
				'',
				'',
				0,
				'',
				'',
				''
			);",
			{
				uid: {cfsqltype: "nvarchar", value: TEST_UID},
				idnumber: {cfsqltype: "integer", value: idnumber}
			}
		);
	}

	/**
	 * Creates a new academic program with the Program status defaulting to Active.
	 * @return the recnum of the new row.
	 */
	public numeric function createAcademicProgram(
		required numeric idnumber, 
		string academicProgramStatus='AC', 
		string career='UGRD'
	) {
		QueryExecute(
			"INSERT INTO dbo.iuieProgram (
				PRSN_UNIV_ID,
				ACAD_CAREER_CD,
				ACAD_LVL_CD,
				ROW_EFF_DT,
				INST_CD,
				ACAD_GRP_CD,
				ACAD_PGM_CD,
				STU_PGM_STAT_CD,
				STU_PGM_ACTN_CD,
				ACAD_PGM_ACTN_DT,
				STU_ADMT_TERM_CD,
				STU_EXPCT_GRAD_TERM_CD,
				STU_DEGR_CKOT_STAT_CD,
				ACAD_PLAN_CD,
				ACAD_PLAN_DESC,
				ACAD_PLAN_TYP_CD,
				ACAD_SUB_PLAN_CD,
				ACAD_SUB_PLAN_DESC,
				PLAN_ONLINE_IND,
				STRUC_DECLARE_DT,
				ACAD_PLAN_DPLM_DESC,
				STU_DEGR_CNFR_DT,
				STU_CUM_GPA_NBR,
				ACAD_PLAN_SEQ_NBR,
				CIP_CODE,
				idnumber,
				ACAD_DEG_CD,
				ACAD_DEPT_CD,
				PPLSFT_ACAD_ORG_HIER_VAL,
				ORG_DEPT_COLLEGE_CD,
				ORG_DEPT_SCHOOL_CD,
				ORG_DEPT_DIVISION_CD
			)
			VALUES (
				:universityid,
				:career,
				:academicLevel,
				dbo.fnTrunc( CURRENT_TIMESTAMP ),
				:campus,
				'',
				'',
				:academicProgramStatus,
				'',
				dbo.fnTrunc( CURRENT_TIMESTAMP ),
				'',
				'',
				'',
				'',
				'',
				'',
				'',
				'',
				'',
				dbo.fnTrunc( CURRENT_TIMESTAMP ),
				'',
				dbo.fnTrunc( CURRENT_TIMESTAMP ),
				3.0,
				1,
				'',
				:idnumber,
				'',
				'',
				'',
				'',
				'',
				''
			);",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				universityid: {cfsqltype: "nvarchar", value: TEST_UID},
				campus: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE},
				career: {cfsqltype: "nvarchar", value: career},
				academicLevel: {cfsqltype: "nvarchar", value: '30'},
				academicProgramStatus: {cfsqltype: "nvarchar", value: academicProgramStatus}
			},
			{result: "local.result"}
		);

		return result.GENERATEDKEY;
	}

	/**
	 * Creates core I-20  for the student, updating jbInternational to match 
	 * Sets program to be active by default, with start -1 month, end +1 month from now
	 * Sets currentSessionStart -1 month, currentSessionEnd + 1 month, nextSessionStart +2 months from now
	 * @return the sevisid
	 */
	public string function createI20Record(
		required numeric idnumber, 
		string sevisStatus = 'A', 
		string eduLevel = '04',
		string primary = '00.0000'
	) {
		var sevisid = Left('N' & NumberFormat(idnumber,'0000000000').toString(),11);
		var orgCode = F1_ORG_CODE;

		QueryExecute(
			"INSERT INTO dbo.sevisI20Program (
				idnumber,
				sevisid,
				status,
				eduLevel,
				eduComments,
				primaryMajor,
				secondMajor,
				minor,
				lengthOfStudy,
				prgStartDate,
				prgEndDate,
				engRequired,
				engRequirementsMet,
				engNotRequired,
				datestamp,
				institutionalKey,
				issDate
			)
			VALUES (
				:idnumber,
				:sevisid,
				:sevisStatus,
				:eduLevel,
				N'',
				N'',
				N'',
				N'',
				N'',
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, 1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				0,
				0,
				N'',
				CURRENT_TIMESTAMP,
				N'',
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP ))
			);",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid},
                sevisStatus: {cfsqltype: "nvarchar", value: sevisStatus},
				eduLevel: {cfsqltype: "nvarchar", value: eduLevel},
				primary: {cfsqltype: "nvarchar", value: primary}
            }
		);
		
		QueryExecute(
			"INSERT INTO dbo.sevisI20Ext (
				idnumber,
				sevisid,
				currentSessionStart,
				currentSessionEnd,
				nextSessionStart,
				commuter,
				admissionNumber,
				datestamp,
				lastSession,
				statusCancelReason,
				statusTerminateReason,
				statusRemarks,
				capGapStatus,
				disciplineExpl,
				levelRemarks,
				programRemarks,
				extExplanation,
				registrationRemarks,
				reprintReason,
				reprintRemarks,
				terminateOtherReason,
				studyResearchAbroad,
				thesisDissertation,
				registrationEligibility
			)
			VALUES (
				:idnumber,
				:sevisid,
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, 1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, 2, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				0,
				N'',
				CURRENT_TIMESTAMP,
				0,
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				0,
				0,
				N''
			);", 
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid}
            }
		);	

		QueryExecute(
			"INSERT INTO dbo.sevisI20Financial (
				idnumber,
				sevisid,
				academicTerm,
				tuition,
				livingExpenses,
				dependentExp,
				otherExpAmount,
				otherExpDesc,
				personalFunds,
				schoolFundsAmount,
				schoolFundsDesc,
				otherFundsAmount,
				otherFundsDesc,
				employmentFunds,
				remarks,
				datestamp
			)
			VALUES (
				:idnumber,
				:sevisid,
				N'',
				0,
				0,
				0,
				0,
				N'',
				0,
				0,
				N'',
				0,
				N'',
				0,
				N'',
				CURRENT_TIMESTAMP
			);", 
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid}
            }
		);

		QueryExecute(
			"UPDATE dbo.jbInternational
			SET
				jbInternational.sevisid = :sevisid,
				jbInternational.orgCode = :orgCode,
				jbInternational.immigrationstatus = :immigrationstatus
			WHERE jbInternational.idnumber = :idnumber;",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid},
				orgCode: {cfsqltype: "nvarchar", value: orgCode},
				immigrationstatus: {cfsqltype: "nvarchar", value: 'F-1'}
            }
		);

		return sevisid;
	}

	/**
	 * Creates an OPT record for the student,.
	 * Sets the status to be approved by default,
	 * and the complettion type to STEM, or 03.
	 * @return the generated recnum.
	 */
	public numeric function createSEVISI20OPT(
		required numeric idnumber,
        required string sevisid,
        string completionType = '03'
	) {
        QueryExecute(
			"INSERT INTO dbo.sevisI20OPT (
				idnumber,
				sevisid,
				status,
				uscisStartDate,
				uscisEndDate,
				timeCode,
				signdate,
				receiptdate,
				noticedate,
				reciudate,
				senthere,
				remarks,
				datestamp,
				receiptNumber,
				academicYearMet,
				studentRemarks,
				completionType,
				recommendStartDate,
				recommendEndDate,
				inSEVIS,
				actualStartDate,
				actualEndDate,
				sevisRTIEmploymentId,
				daysUnemployed,
				validationCompleted,
				validatedOn,
				completedSelfEval,
				evaluatedOn
			)
			VALUES (
				:idnumber,
				:sevisid,
				N'Approved',
				GETDATE(),
				DATEADD( YEAR, 1, GETDATE()),
				N'',
				GETDATE(),
				GETDATE(),
				GETDATE(),
				GETDATE(),
				0,
				N'',
				GETDATE(),
				N'',
				1,
				N'',
				:completionType,
				GETDATE(),
				DATEADD( YEAR, 1, GETDATE()),
				1,
				GETDATE(),
				DATEADD( YEAR, 1, GETDATE()),
				0,
				0,
				0,
				GETDATE(),
				0,
				GETDATE()
			);", 
            {
                idnumber: {cfsqltype: "integer", value: idnumber},
                sevisid: {cfsqltype: "nvarchar", value: sevisid},
                completionType: {cfsqltype: "nvarchar", value: completionType}
            },
			{result: "local.result"}
		);

		return result.GENERATEDKEY;
    }

	/**
	 * Creates an CPT record for the student.
	 * Sets the status to be approved by default.
	 * @return the generated recnum.
	 */
	public void function createSEVISI20CPT(
		required numeric idnumber,
        required string sevisid
	) {
        QueryExecute(
			"INSERT INTO dbo.sevisI20CPT (
				idnumber,
				sevisid,
				status,
				startDate,
				endDate,
				timeCode,
				datestamp
			)
			VALUES (
				:idnumber,
				:sevisid,
				N'Approved',
				DATEADD( DAY, -30, CURRENT_TIMESTAMP ),
				DATEADD( DAY, 30, CURRENT_TIMESTAMP ),
				'01',
				CURRENT_TIMESTAMP
			);", 
            {
                idnumber: {cfsqltype: "integer", value: idnumber},
                sevisid: {cfsqltype: "nvarchar", value: sevisid}
            }
		);
    }

	/**
	 * Creates core DS-2019 for the student, updating jbInternational to match 
	 * Sets program to be active by default and student, with start -1 month, end +1 month from now
	 * @return the sevisid
	 */
	public string function createDS2019Record(
		required numeric idnumber, 
		string sevisStatus = 'A', 
		string categoryCode = '1C',
		string subjectField = '00.0000'
	) {
		var sevisid = Left('N' & NumberFormat(idnumber,'0000000000').toString(),11);
		var orgCode = J1_ORG_CODE;

		QueryExecute(
			"INSERT INTO dbo.sevisDS2019Program (
				idnumber,
				sevisid,
				status,
				categoryCode,
				positionCode,
				prgStartDate,
				prgEndDate,
				subjectFieldCode,
				subjectFieldRemarks,
				datestamp,
				foreignDegreeLevel,
				foreignFieldOfStudy,
				institutionalKey,
				validatedOn
			)
			VALUES	(
				:idnumber,
				:sevisid,
				:sevisStatus,
				:categoryCode,
				0,
				DATEADD(MONTH, -1, dbo.fnTrunc(CURRENT_TIMESTAMP)),
				DATEADD(MONTH, 1, dbo.fnTrunc(CURRENT_TIMESTAMP)),
				:subjectField,
				N'',
				CURRENT_TIMESTAMP,
				N'',
				N'',
				N'',
				DATEADD(MONTH, -1, dbo.fnTrunc(CURRENT_TIMESTAMP))
			);", 
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid},
                sevisStatus: {cfsqltype: "nvarchar", value: sevisStatus},
                categoryCode: {cfsqltype: "nvarchar", value: categoryCode},
				subjectField: {cfsqltype: "nvarchar", value: subjectField}
			}
		);

		QueryExecute(
			"INSERT INTO dbo.sevisDS2019Ext (
				idnumber,
				sevisid,
				datestamp,
				enrollNotRequired,
				statusReason,
				statusRemarks,
				reprintReason,
				reprintRemarks,
				programRemarks,
				statusTerminateReason,
				terminateStatusOtherRemarks,
				homeCountryPositionCode,
				reprintOtherRemarks,
				matriculation,
				infractionType,
				occupationCategory,
				monthsInStatus,
				has2YearHomeResReq,
				waiverGranted
			)
			VALUES (
				:idnumber,
				:sevisid,
				CURRENT_TIMESTAMP,
				0,
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				N'',
				0,
				0,
				0
			);", 
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid}
            }
		);	

		QueryExecute(
			"INSERT INTO dbo.sevisDS2019Financial (
				idnumber,
				sevisid,
				receivedUSGovFunds,
				programSponsorFunds,
				govtOrg1,
				govtOrg1Amount,
				govtOrg2,
				govtOrg2Amount,
				internatOrg1,
				internatOrg1Amount,
				internatOrg2,
				internatOrg2Amount,
				evGovt,
				binationalCommission,
				otherOrgNames,
				otherOrg,
				personalFunds,
				remarks,
				datestamp,
				otherGovtOrg1Name,
				otherGovtOrg2Name,
				otherInternatOrg1Name,
				otherInternatOrg2Name
			)
			VALUES (
				:idnumber,
				:sevisid,
				0,
				0,
				N'',
				0,
				N'',
				0,
				N'',
				0,
				N'',
				0,
				0,
				0,
				N'',
				0,
				0,
				N'',
				CURRENT_TIMESTAMP,
				N'',
				N'',
				N'',
				N''
			);", 
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid}
            }
		);

		QueryExecute(
			"UPDATE dbo.jbInternational
			SET
				jbInternational.sevisid = :sevisid,
				jbInternational.orgCode = :orgCode,
				jbInternational.immigrationstatus = :immigrationstatus
			WHERE jbInternational.idnumber = :idnumber;",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid},
				orgCode: {cfsqltype: "nvarchar", value: orgCode},
				immigrationstatus: {cfsqltype: "nvarchar", value: 'J1'}
            }
		);

		return sevisid;
	}

	/**
	 * Creates core H1B for the student, updating jbInternational to match 
	 * Sets LCA/H1B to be active by default, with start -1 month, end +1 month from now
	 * @return the LCA Number
	 */
	public string function createH1BRecord(
		required numeric idnumber, 
		string status = 'A'
	) {
		var lcaNumber = Left('N' & NumberFormat(idnumber,'0000000000').toString(),11);
		var positionNumber = Left('N' & NumberFormat(idnumber,'0000000000').toString(),11);

		QueryExecute(
			"INSERT INTO dbo.jbEmployeeH1BInfo (
				idnumber,
				approvalStartDate,
				approvalEndDate,
				lcaNumber,
				requiredStartDate,
				receiptNoticeDate,
				petitionApprovalDate,
				rfeDate,
				rfeResponseDate,
				positionNumber,
				petitionMailedDate,
				linNumber,
				inspectionFileCreated,
				billingStartDate,
				ppReceiptNoticeDate,
				datestamp,
				originalApprovalStartDate,
				originalApprovalEndDate,
				immigrationStatus,
				status,
				type,
				verification,
				excludePositionNumber,
				effectiveDate,
				alienANumber,
				socCode,
				appointmentTitle,
				lawyerName,
				givenToLawyer
			)
			VALUES (
				:idnumber,
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, 1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				:lcaNumber,
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				:positionNumber,
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				N'',
				1,
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				CURRENT_TIMESTAMP,
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, 1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				N'H1B',
				:status,
				N'',
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				N'',
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				N'',
				N'',
				N'',
				N'',
				0
			);", 
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				positionNumber: {cfsqltype: "nvarchar", value: positionNumber},
				lcaNumber: {cfsqltype: "nvarchar", value: lcaNumber},
				status: {cfsqltype: "nvarchar", value: status}
            }
		);

		QueryExecute(
			"INSERT INTO dbo.jbEmployeeLCA (
				idnumber,
				positionTitle,
				numberOf,
				departmentLocation,
				occupationClassification,
				lcaStartDate,
				lcaEndDate,
				lcaNumber,
				actualWage,
				prevailingWage,
				salary,
				minimumRequiredWage,
				postStartDate,
				postEndDate,
				datestamp,
				publicInspectionFileLocation,
				prevailingWageSubmit,
				prevailingWageReceived,
				prevailingWageNumber,
				lcaStatus,
				campus
			)
			VALUES (
				:idnumber,
				N'',
				1,
				N'',
				N'',
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, 1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				:lcaNumber,
				0,
				0,
				0,
				0,
				DATEADD( MONTH, -3, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, -2, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				CURRENT_TIMESTAMP,
				N'',
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				N'',
				:status,
				:campus
			);", 
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				lcaNumber: {cfsqltype: "nvarchar", value: lcaNumber},
				status: {cfsqltype: "nvarchar", value: status},
				campus: {cfsqltype: "nvarchar", value: TEST_CAMPUS_CODE}
            }
		);

		updateJBInternationalH1B(idnumber);

		return lcaNumber;
	}

	private void function updateJBInternationalH1B( required numeric idnumber ) {			  
		QueryExecute("
			UPDATE dbo.jbInternational
			SET immigrationstatus = 'H1B'
			WHERE idnumber = :idnumber",
            {
                idnumber: {cfsqltype: "integer", value: idnumber}
            }
		);
    }
}
