component {

	/**
	 * Creates a new student with the given university id (defaults to "TEST"),
	 * 'TOC' as campus, and it can take immigrationStatus as an
	 * argument, but if not given the argument it will default to
	 * 'F-1'.
	 * @return the new idnumber
	 */
	public numeric function createRecord(
		string immigrationStatus="F-1", 
		string orgCode="",
		string universityid=getUID()
	) {
		// create a campus first
		new ConfigDataHandler().setupTestCampus();

		var person = QueryExecute(
			"DECLARE @inserted TABLE (
				idnumber INT NOT NULL
			);
			INSERT INTO dbo.jbInternational (
				universityid,
				orgCode,
				campus,
				immigrationstatus
			)
			OUTPUT Inserted.idnumber
			INTO @inserted
			VALUES (
				:uid,
				:orgCode,
				:campus,
				:immigrationStatus
			);
			SELECT [@inserted].idnumber FROM @inserted;",
			{
				uid: {cfsqltype: "nvarchar", value: universityid},
				orgCode: {cfsqltype: "nvarchar", value: new ConfigDataHandler().getF1OrgCode()},
				campus: {cfsqltype: "nvarchar", value: new ConfigDataHandler().getCampus()},
				immigrationStatus: {cfsqltype: "nvarchar", value: immigrationStatus}
			}
		);

		QueryExecute(
			"INSERT INTO dbo.jbInternationalBioExt ( idnumber ) VALUES ( :idnumber );",
			{ idnumber: {cfsqltype: "integer", value: person.idnumber} }
		);

		QueryExecute(
			"INSERT INTO dbo.jbCommunication ( idnumber ) VALUES ( :idnumber );",
			{ idnumber: {cfsqltype: "integer", value: person.idnumber} }
		);

		return person.idnumber;
	}

	/**
	 * This is just a getter function for the university id.
	 * @return the hard-coded university id
	 */
	public string function getUID() {
		return "TEST";
	}

	/**
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
		var override = QueryExecute(
			"INSERT INTO dbo.jbAlertsOverride (
				idnumber,
				serviceID,
				semester,
				username,
				datestamp,
				endDate,
				forever
			)
			OUTPUT Inserted.recnum
			VALUES (
				:idnumber,
				:alertService,
				NULL,
				N'ioffice_admin',
				CURRENT_TIMESTAMP,
				DATEADD( DAY, :endDateOffset, CONVERT( DATE, CURRENT_TIMESTAMP )),
				:forever
			);",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				alertService: {cfsqltype: "nvarchar", value: alertService},
				forever: {cfsqltype: "bit", value: forever},
				endDateOffset: {cfsqltype: "integer", value: endDateOffset}
			}
		);

		return override.recnum;
	}

	/**
	 * configures an admission record for a future term
	 * returns the application number (which is the same as the recnum)
	 *
	 * @idnumber the student to add the admission record to
	 */
	public string function createAdmissionRecord(
		required numeric idnumber,
		string admitStatus="AC",
		numeric startOffset=-30,
		string admitType = "FYU"
	) {
		var term = new ConfigDataHandler().createTerm(startOffset: startOffset);

		var admissionQuery = QueryExecute(
			"INSERT INTO dbo.iuieAdmissions (
				PRSN_UNIV_ID,
				INST_CD,
				APPL_PGM_STAT_CD,
				STU_ADMT_TYP_CD,
				STU_ADMT_TERM_CD,
				STU_ADMT_TERM_BEG_DT,
				STU_ADMT_TERM_END_DT,
				idnumber
			)
			OUTPUT Inserted.recnum
			SELECT
				jbInternational.universityid,
				jbInternational.campus,
				:admitStatus,
				:admitType,
				configTerm.term,
				configTerm.startDate,
				configTerm.endDate,
				jbInternational.idnumber
			FROM dbo.jbInternational
			INNER JOIN dbo.configTerm
				ON configTerm.campus = jbInternational.campus
					AND configTerm.term = :term
			WHERE jbInternational.idnumber = :idnumber;",
			{
				admitStatus: {cfsqltype: "varchar", value: admitStatus},
				admitType: {cfsqltype: "varchar", value: admitType},
				term: {cfsqltype: "varchar", value: term},
				idnumber: {cfsqltype: "integer", value: idnumber}
			}
		);

		QueryExecute(
			"UPDATE dbo.iuieAdmissions
			SET iuieAdmissions.APPL_NBR = :recnum
			WHERE iuieAdmissions.recnum = :recnum;",
			{ recnum: admissionQuery.recnum }
		);

		return admissionQuery.recnum;
	}

	/**
	 * Creates an enrollment row in jbStudentTerm,
	 * using the given idnumber, and term code.
	 * It defaults the career type to UGRD,
	 * and the academic level to 30.
	 *
	 * It also adds a row in iuieCourses,
	 * using the given idnumber, and corresponding university id.
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
			SELECT
				jbInternational.idnumber,
				configTerm.term,
				jbInternational.campus,
				configTerm.startDate,
				configTerm.endDate,
				:credits,
				0.0,
				N'E',
				:career,
				N'30',
				N'',
				jbInternational.immigrationstatus,
				0,
				0,
				1,
				N'',
				0
			FROM dbo.jbInternational
			INNER JOIN dbo.configTerm
				ON configTerm.campus = jbInternational.campus
					AND configTerm.term = :term
			WHERE jbInternational.idnumber = :idnumber;",
			{
				credits: {cfsqltype: "integer", value: credits},
				career: {cfsqltype: "nvarchar", value: career},
				term: {cfsqltype: "nvarchar", value: term},
				idnumber: {cfsqltype: "integer", value: idnumber}
			}
		);

		QueryExecute(
			"INSERT INTO dbo.iuieCourses (
				idnumber,
				PRSN_UNIV_ID,
				ACAD_UNT_TKN_NBR,
				STU_ENRL_STAT_CD
			)
			SELECT
				jbInternational.idnumber,
				jbInternational.universityid,
				3.000,
				'E'
			FROM dbo.jbInternational
			WHERE jbInternational.idnumber = :idnumber;",
			{ idnumber: {cfsqltype: "integer", value: idnumber}	}
		);
	}

	/**
	 * Creates a new academic program with the Program status defaulting to Active.
	 * @return the recnum of the new row.
	 */
	public numeric function createAcademicProgram(
		required numeric idnumber,
		string academicProgramStatus="AC",
		string career="UGRD"
	) {
		var program = QueryExecute(
			"INSERT INTO dbo.iuieProgram (
				idnumber,
				PRSN_UNIV_ID,
				ACAD_CAREER_CD,
				INST_CD,
				ACAD_PGM_CD,
				STU_PGM_STAT_CD,
				ACAD_PGM_ACTN_DT,
				STU_ADMT_TERM_CD,
				ACAD_PLAN_CD,
				ACAD_PLAN_TYP_CD,
				PLAN_ONLINE_IND,
				STU_DEGR_CNFR_DT,
				CIP_CODE
			)
			OUTPUT Inserted.recnum
			SELECT
				jbInternational.idnumber,
				jbInternational.universityid,
				:career,
				jbInternational.campus,
				'',
				:academicProgramStatus,
				CONVERT( DATE, CURRENT_TIMESTAMP ),
				'',
				'',
				'',
				'',
				NULL,
				''
			FROM dbo.jbInternational
			WHERE jbInternational.idnumber = :idnumber;",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				career: {cfsqltype: "varchar", value: career},
				academicProgramStatus: {cfsqltype: "varchar", value: academicProgramStatus}
			}
		);

		return program.recnum;
	}

	/**
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
		var sevisid = Left("N" & NumberFormat(idnumber, "0000000000"), 11);

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
				:primary,
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
			"UPDATE dbo.jbInternational
			SET
				jbInternational.sevisid = :sevisid,
				jbInternational.orgCode = :orgCode,
				jbInternational.immigrationstatus = 'F-1'
			WHERE jbInternational.idnumber = :idnumber;",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid},
				orgCode: {cfsqltype: "nvarchar", value: new ConfigDataHandler().getF1OrgCode()}
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
		string completionType="03"
	) {
		var offset = completionType == "03" ? 2 : 1;
		var opt = QueryExecute(
			"DECLARE @optrecnum TABLE (
				recnum INT NOT NULL
			);
			INSERT INTO dbo.sevisI20OPT (
				idnumber,
				sevisid,
				status,
				uscisStartDate,
				uscisEndDate,
				timeCode,
				remarks,
				receiptNumber,
				academicYearMet,
				studentRemarks,
				completionType,
				recommendStartDate,
				recommendEndDate,
				inSEVIS,
				actualStartDate,
				actualEndDate
			)
			OUTPUT Inserted.recnum
			INTO @optrecnum
			VALUES (
				:idnumber,
				:sevisid,
				N'Approved',
				CONVERT( DATE, CURRENT_TIMESTAMP ),
				CONVERT( DATE, DATEADD( YEAR , :offset, CURRENT_TIMESTAMP )),
				N'',
				N'',
				N'',
				1,
				N'',
				:completionType,
				CONVERT( DATE, CURRENT_TIMESTAMP ),
				CONVERT( DATE, DATEADD( YEAR , :offset, CURRENT_TIMESTAMP )),
				1,
				CONVERT( DATE, CURRENT_TIMESTAMP ),
				CONVERT( DATE, DATEADD( YEAR , :offset, CURRENT_TIMESTAMP ))
			);
			SELECT [@optrecnum].recnum FROM @optrecnum;",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid},
				completionType: {cfsqltype: "nvarchar", value: completionType},
				offset: {cfsqltype: "integer", value: offset}
			}
		);

		return opt.recnum;
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
				DATEADD( DAY, -30, CONVERT( DATE, CURRENT_TIMESTAMP )),
				DATEADD( DAY, 30, CONVERT( DATE, CURRENT_TIMESTAMP )),
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
		string sevisStatus="A",
		string categoryCode="1C",
		string subjectField="00.0000"
	) {
		var sevisid = Left("N" & NumberFormat(idnumber, "0000000000"), 11);
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
			VALUES (
				:idnumber,
				:sevisid,
				:sevisStatus,
				:categoryCode,
				0,
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, 1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				:subjectField,
				N'',
				CURRENT_TIMESTAMP,
				N'',
				N'',
				N'',
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP ))
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
				jbInternational.immigrationstatus = 'J1'
			WHERE jbInternational.idnumber = :idnumber;",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				sevisid: {cfsqltype: "nvarchar", value: sevisid},
				orgCode: {cfsqltype: "nvarchar", value: orgCode}
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
		string status="A"
	) {
		var base = Left(NumberFormat(idnumber, "00000000000"), 11);
		var lcaNumber = "I-200-#Left(base, 5)#-#Right(base, 6)#";
		var prevailingWageNumber = "P-200-#Left(base, 5)#-#Right(base, 6)#";
		var positionNumber = Right(base, 8);

		QueryExecute(
			"INSERT INTO dbo.iuieEmployee (
				PRSN_UNIV_ID,
				EMP_STAT_CD,
				POS_NBR,
				idnumber
			)
			SELECT
				jbInternational.universityid,
				:status,
				:positionNumber,
				jbInternational.idnumber
			FROM dbo.jbInternational
			WHERE jbInternational.idnumber = :idnumber;",
			{
				status: {cfsqltype: "varchar", value: status},
				positionNumber: {cfsqltype: "varchar", value: positionNumber},
				idnumber: {cfsqltype: "integer", value: idnumber}
			}
		);

		QueryExecute(
			"INSERT INTO dbo.jbEmployeeH1BInfo (
				idnumber,
				positionNumber,
				approvalStartDate,
				approvalEndDate,
				lcaNumber,
				requiredStartDate,
				receiptNoticeDate,
				petitionApprovalDate,
				rfeDate,
				rfeResponseDate,
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
				:positionNumber,
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( MONTH, 1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				:lcaNumber,
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( DAY, -55, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				DATEADD( DAY, -45, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				NULL,
				NULL,
				NULL,
				N'',
				1,
				NULL,
				NULL,
				CURRENT_TIMESTAMP,
				NULL,
				NULL,
				N'H1B',
				N'P',
				1,
				NULL,
				N'',
				DATEADD( MONTH, -1, dbo.fnTrunc( CURRENT_TIMESTAMP )),
				N'',
				N'',
				N'',
				N'',
				NULL
			);",
			{
				idnumber: {cfsqltype: "integer", value: idnumber},
				positionNumber: {cfsqltype: "nvarchar", value: positionNumber},
				lcaNumber: {cfsqltype: "nvarchar", value: lcaNumber}
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
			SELECT
				jbInternational.idnumber,
				N'',
				1,
				N'',
				N'',
				DATEADD( MONTH, -1, CONVERT( DATE, CURRENT_TIMESTAMP )),
				DATEADD( MONTH, 1, CONVERT( DATE, CURRENT_TIMESTAMP )),
				:lcaNumber,
				0,
				0,
				0,
				0,
				DATEADD( MONTH, -3, CONVERT( DATE, CURRENT_TIMESTAMP )),
				DATEADD( MONTH, -2, CONVERT( DATE, CURRENT_TIMESTAMP )),
				CURRENT_TIMESTAMP,
				N'',
				DATEADD( YEAR, -1, CONVERT( DATE, CURRENT_TIMESTAMP )),
				DATEADD( MONTH, -6, CONVERT( DATE, CURRENT_TIMESTAMP )),
				:prevailingWageNumber,
				N'P',
				jbInternational.campus
			FROM dbo.jbInternational
			WHERE jbInternational.idnumber = :idnumber;",
			{
				lcaNumber: {cfsqltype: "nvarchar", value: lcaNumber},
				prevailingWageNumber: {cfsqltype: "nvarchar", value: prevailingWageNumber},
				idnumber: {cfsqltype: "integer", value: idnumber}
			}
		);

		QueryExecute("
			UPDATE dbo.jbInternational
			SET immigrationstatus = 'H1B'
			WHERE idnumber = :idnumber",
			{
				idnumber: {cfsqltype: "integer", value: idnumber}
			}
		);

		return positionNumber;
	}

	public numeric function addToChecklist(
		required numeric idnumber, 
		required string speciesKey, 
		string subSpecies=""
	) {
		var requestGroup = QueryExecute(
			"INSERT INTO dbo.jbEFormGroup (
				groupTitle,
				started,
				ended,
				datestamp,
				idnumber,
				groupID,
				campus
			)
			OUTPUT Inserted.recnum
			SELECT
				codeChecklistSpecies.eFormGroupTitle,
				CURRENT_TIMESTAMP,
				NULL,
				CURRENT_TIMESTAMP,
				jbInternational.idnumber,
				codeChecklistSpecies.eformGroupID,
				jbInternational.campus
			FROM dbo.jbInternational
			INNER JOIN dbo.codeChecklistSpecies
				ON codeChecklistSpecies.speciesKey = :speciesKey
			WHERE jbInternational.idnumber = :idnumber;",
			{
				speciesKey: {cfsqltype: "nvarchar", value: speciesKey},
				idnumber: {cfsqltype: "integer", value: idnumber}
			}
		);

		var eformGroup = requestGroup.recnum;

		var checklist = QueryExecute(
			"INSERT INTO dbo.jbChecklist (
				idnumber,
				subspeciesSpecifier,
				datestamp,
				display01,
				display02,
				display03,
				display04,
				eformGroup,
				checklistType,
				section,
				subspeciesDescription
			)
			OUTPUT Inserted.checklistID
			SELECT
				jbEFormGroup.idnumber,
				IIF(codeChecklistSpecies.checklistType = 'I01', jbEFormGroup.recnum, :subSpecies),
				jbEFormGroup.started,
				N'',
				N'',
				N'',
				N'',
				jbEFormGroup.recnum,
				codeChecklistSpecies.checklistType,
				jbEFormGroup.idnumber % 10,
				N''
			FROM dbo.jbEFormGroup
			INNER JOIN dbo.codeChecklistSpecies
				ON codeChecklistSpecies.speciesKey = :speciesKey
			WHERE jbEFormGroup.recnum = :eformGroup;",
			{
				subSpecies: {cfsqltype: "nvarchar", value: subSpecies},
				speciesKey: {cfsqltype: "nvarchar", value: speciesKey},
				eformGroup: {cfsqltype: "integer", value: eformGroup}
			}
		);

		var checklistID = checklist.checklistID;

		QueryExecute(
			"INSERT INTO dbo.jbChecklistSpeciesKey (
				idnumber,
				speciesKey,
				checklistID,
				onList,
				datestamp
			)
			SELECT
				jbChecklist.idnumber,
				:speciesKey,
				jbChecklist.checklistID,
				1,
				jbChecklist.datestamp
			FROM dbo.jbChecklist
			WHERE jbChecklist.checklistID = :checklistID;",
			{
				speciesKey: {cfsqltype: "nvarchar", value: speciesKey},
				checklistID: {cfsqltype: "integer", value: checklistID}
			}
		);

		QueryExecute(
			"INSERT INTO dbo.jbChecklistStage (
				idnumber,
				stage,
				openStage,
				username,
				datestamp,
				entryDate,
				checklistID,
				exitDate
			)
			SELECT
				jbChecklist.idnumber,
				N's1',
				1,
				N'system',
				jbChecklist.datestamp,
				jbChecklist.datestamp,
				jbChecklist.checklistID,
				NULL
			FROM dbo.jbChecklist
			WHERE jbChecklist.checklistID = :checklistID;",
			{ checklistID: {cfsqltype: "nvarchar", value: checklistID } }
		);

		return checklistID;
	}

}