component {

	/**
	 * This is just a getter function for F1 org code.
	 * @return the F1 SEVIS Organization code
	 */
	public string function getF1OrgCode() {
		return "SEA214F28700003";
	}

	/**
	 * This is just a getter function for J1 org code.
	 * @return the J1 SEVIS Organization code
	 */
	public string function getJ1OrgCode() {
		return "P-1-00104";
	}

	/**
	 * This is just a getter function for the campus.
	 * @return the hard-coded campus
	 */
	public string function getCampus() {
		return "TOC";
	}

	/**
	 * This is just a getter function for the campus name.
	 * @return the hard-coded campus description
	 */
	public string function getCampusDescription() {
		return "Test Only Campus";
	}

	/**
	 * This is just a getter function for alertGroup.
	 * @return the hard-coded alertGroup
	 */
	public string function getAlertGroup() {
		return "testonly";
	}

	public string function getTermCode() {
		return "TEST";
	}

	/**
	 * This sets up the test campus information
	 * and information in mapCampusApplicationArea
	 * needed to run the tests.
	 * @retrns the campus code
	 */
	public void function setupTestCampus() {
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
				campusCode: {cfsqltype: "nvarchar", value: getCampus()},
				campusDescription: {cfsqltype: "nvarchar", value: getCampusDescription()}
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
				campusCode: {cfsqltype: "nvarchar", value: getCampus()}
			}
		);

		QueryExecute(
			"MERGE dbo.codeSEVISOrg
			USING (
				SELECT :f1orgcode AS orgCode
			) AS source
			ON source.orgCode = codeSEVISOrg.orgCode
			WHEN MATCHED
				THEN UPDATE SET codeSEVISOrg.campusList += :campusCode + ','
			WHEN NOT MATCHED
				THEN INSERT (
						orgCode,
						visaType,
						description,
						fullDescription,
						PDSORO,
						campus,
						campusList
					)
					VALUES (
						source.orgCode,
						'F-1',
						'Test SEVIS Org',
						'Test SEVIS Organization',
						'tpdso-0000',
						:campusCode,
						:campusCode + ','
					);",
			{
				campusCode: {cfsqltype: "nvarchar", value: getCampus()},
				f1orgcode: {cfsqltype: "nvarchar", value: getF1OrgCode()}
			}
		);

		QueryExecute(
			"MERGE dbo.codeSEVISOrg
			USING (
				SELECT :j1orgcode AS orgCode
			) AS source
			ON source.orgCode = codeSEVISOrg.orgCode
			WHEN MATCHED
				THEN UPDATE SET codeSEVISOrg.campusList += :campusCode + ','
			WHEN NOT MATCHED
				THEN INSERT (
						orgCode,
						visaType,
						description,
						fullDescription,
						PDSORO,
						campus,
						campusList
					)
					VALUES (
						source.orgCode,
						'J-1',
						'Test SEVIS Org',
						'Test SEVIS Organization',
						'tpdso-0000',
						:campusCode,
						:campusCode + ','
					);",
			{
				campusCode: {cfsqltype: "nvarchar", value: getCampus()},
				j1orgcode: {cfsqltype: "nvarchar", value: getJ1OrgCode()}
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
				alertGroup: {cfsqltype: "nvarchar", value: getAlertGroup()},
				campus: {cfsqltype: "nvarchar", value: getCampus()}
			}
		);
		
		QueryExecute(
			"MERGE INTO dbo.codeAlertGroups
			USING (
				SELECT 
					:alertGroup AS code,
					'Test Only Alert Group' AS description,
					'email@fake.edu' AS email,
					:campus AS campus
			) AS source
			ON source.code = codeAlertGroups.code
			WHEN NOT MATCHED
				THEN INSERT (
					code,
					description,
					email,
					campus
				)
				VALUES (   
					source.code,
					source.description,
					source.email,
					source.campus
				);",		
					
			{
				alertGroup: {cfsqltype: "nvarchar", value: getAlertGroup()},
				campus: {cfsqltype: "nvarchar", value: getCampus()}
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
				alertGroup: {cfsqltype: "nvarchar", value: getAlertGroup()},
				orgCode: {cfsqltype: "nvarchar", value: getF1OrgCode()}
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
				alertGroup: {cfsqltype: "nvarchar", value: getAlertGroup()},
				orgCode: {cfsqltype: "nvarchar", value: getJ1OrgCode()}
			}
		);
	}

	/**
	 * make sure that a term is configured
	 *
	 * @termCode The code to use (defaults to "test")
	 * @startOffset the number of days until the term start (default is -30 - the term starts a month ago)
	 * @endOffset the number of days in the term (default is 120 - the term ends is 4 months long)
	 */
	public string function createTerm(
		string termCode=getTermCode(), 
		string campus=getCampus(), 
		numeric startOffset=-30, 
		numeric length=120
	) {
		QueryExecute(
			"MERGE dbo.codeTermType
			USING (
				SELECT
					N'req' AS code,
					N'Required' AS description,
					1 AS required,
					1 AS sevis,
					1 AS opendoors
				UNION
				SELECT
					N'opt' AS code,
					N'Optional' AS description,
					0 AS required,
					0 AS sevis,
					0 AS opendoors
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
					);"
		);

		QueryExecute(
			"MERGE dbo.codeTerm
			USING (
				SELECT
					:term AS code,
					'req' AS type,
					YEAR( CURRENT_TIMESTAMP ) AS year,
					N'Test Term' AS moreDescription,
					:term AS reportCode,
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
			{ term: {cfsqltype: "nvarchar", value: termCode} }
		);

		QueryExecute(
			"MERGE dbo.configTerm
			USING (
				SELECT
					:term AS term,
					:campus AS campus,
					CONVERT( DATE, DATEADD( DAY, :startOffset, CURRENT_TIMESTAMP )) AS startDate,
					CONVERT( DATE, DATEADD( DAY, :endOffset, CURRENT_TIMESTAMP )) AS endDate
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
				term: {cfsqltype: "nvarchar", value: termCode},
				campus: {cfsqltype: "nvarchar", value: campus},
				startOffset: {cfsqltype: "integer", value: startOffset},
				endOffset: {cfsqltype: "integer", value: startOffset + length}
			}
		);

		return termCode;
	}

	public void function setOptional(required string term) {
		QueryExecute(
			"UPDATE dbo.codeTerm SET codeTerm.type = 'opt' WHERE codeTerm.code = :term;",
			{ term: {cfsqltype: "nvarchar", value: term} }
		);
	}

	/**
	 * configures a row for the term at the "TOC" campus
	 * to ensure that this is a current term.
	 * @return the term code
	 */
	public string function createCurrentTerm(
		string term=getTermCode(), 
		string campus=getCampus()
	) {
		return createTerm(term, campus);
	}

	/**
	 * configures an e-form group, a checklist, a stage, and populates codeChecklistSpecies
	 * 
	 * Returns the speciesKey
	 */
	public string function createChecklist(
		string type="I02",
		string campus=getCampus(),
		string genus="FYU",
		string species=getTermCode()
	) {
		var eformGroup = QueryExecute(
			"INSERT INTO dbo.IStartEFormGroup (
				title,
				metaInfo,
				icon,
				description,
				datestamp,
				campus,
				menuCategory,
				adminApplicationArea,
				admissionApplicationArea,
				clientApplicationArea,
				requireDepartmentRequest,
				multiSubmit,
				keystoneClosureFlag,
				keystoneDescriptionFlag,
				informationalDisplayOnly,
				defaultAccess
			)
			OUTPUT Inserted.recnum
			VALUES (
				N'Test Group',
				N'',
				N'',
				N'',
				CURRENT_TIMESTAMP,
				:campus,
				N'',
				1,
				1,
				1,
				0,
				0,
				0,
				0,
				0,
				1
			);",
			{ campus: {cfsqltype: "nvarchar", value: getCampus()} }
		);

		var groupID = eformGroup.recnum;

		var checklist = QueryExecute(
			"DECLARE @inserted TABLE (
				familyKey NVARCHAR(5) NOT NULL
			);

			INSERT INTO dbo.configChecklistGroupFamily (
				type,
				eformGroupID,
				campus,
				familyKey,
				pdfStructureID,
				eformGroupRelationship
			)
			OUTPUT Inserted.familyKey
			INTO @inserted
			VALUES (
				:type,
				:groupID,
				:campus,
				CONCAT( N'T', :groupID ),
				N'',
				:relationship
			);
			
			SELECT [@inserted].familyKey FROM @inserted;",
			{
				type: {cfsqltype: "nvarchar", value: type},
				groupID: {cfsqltype: "integer", value: groupID},
				campus: {cfsqltype: "nvarchar", value: getCampus()},
				relationship: {cfsqltype: "nvarchar", value: type == "I01" ? "E2C" : "C2E"}
			}
		);

		var familyKey = checklist.familyKey;

		QueryExecute(
			"INSERT INTO dbo.configChecklistStage (
				code,
				description,
				rank,
				familyKey,
				showIOMAdmissions,
				showSAMParticipation,
				massApproveTask,
				massClearTask,
				kuali,
				displayAdmissionTranscript,
				displayAdmissionDecision,
				displayLetterProduction,
				createImmigrationDocument,
				generateAdmissionLetter
			)
			VALUES (
				's1',
				N'Test Stage',
				1,
				:familyKey,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				N'',
				0
			);",
			{ familyKey: {cfsqltype: "nvarchar", value: familyKey} }
		);

		if( type == "I02" || type == "I05" ) {
			QueryExecute(
				"MERGE codeAdmitType
				USING (
					SELECT
						:genus AS code,
						:genus AS description
				) AS source
				ON source.code = codeAdmitType.code
				WHEN NOT MATCHED
					THEN INSERT (
							code,
							description
						)
						VALUES (
							source.code,
							source.description
						);",
				{genus: {cfsqltype: "nvarchar", value: genus} }
			);

			QueryExecute(
				"INSERT INTO dbo.configFilterChecklistAdmissionGenus (
					familyKey,
					genusSpecifier
				)
				VALUES (
					:familyKey,
					:admitType
				);",
				{
					familyKey: {cfsqltype: "nvarchar", value: familyKey},
					admitType: {cfsqltype: "nvarchar", value: genus}
				}
			);

			QueryExecute(
				"INSERT INTO dbo.configFilterChecklistAdmissionSpecies (
					familyKey,
					speciesSpecifier
				)
				VALUES (
					:familyKey,
					:term
				);",
				{
					familyKey: {cfsqltype: "nvarchar", value: familyKey},
					term: {cfsqltype: "nvarchar", value: species}
				}
			);
		}

		if( ArrayFind(["I01", "I02", "I03", "I05"], type) > 0 ) {
			var speciesKey = QueryExecute(
				"INSERT INTO dbo.codeChecklistSpecies
				(
					checklistType,
					campus,
					campusDescription,
					eformGroupID,
					eFormGroupTitle,
					familyKey,
					genusTitle,
					genusSpecifier,
					genusDescription,
					genusKey,
					speciesTitle,
					speciesSpecifier,
					speciesDescription,
					speciesKey,
					checklistTypeDesc,
					pdfStructureID,
					eformGroupRelationship
				)
				OUTPUT Inserted.speciesKey
				SELECT loadChecklistSpecies.checklistType,
					loadChecklistSpecies.campus,
					loadChecklistSpecies.campusDescription,
					loadChecklistSpecies.eformGroupID,
					loadChecklistSpecies.eFormGroupTitle,
					loadChecklistSpecies.familyKey,
					loadChecklistSpecies.genusTitle,
					loadChecklistSpecies.genusSpecifier,
					loadChecklistSpecies.genusDescription,
					loadChecklistSpecies.genusKey,
					loadChecklistSpecies.speciesTitle,
					loadChecklistSpecies.speciesSpecifier,
					loadChecklistSpecies.speciesDescription,
					loadChecklistSpecies.speciesKey,
					loadChecklistSpecies.checklistTypeDesc,
					loadChecklistSpecies.pdfStructureID,
					loadChecklistSpecies.eformGroupRelationship
				FROM dbo.viewChecklistLoadCodeChecklistSpecies#type# AS loadChecklistSpecies
				WHERE loadChecklistSpecies.familyKey = :familyKey;",
				{ familyKey: {cfsqltype: "nvarchar", value: familyKey} }
			);

			return speciesKey.speciesKey;
		}

		return "";
	}

	public numeric function addChecklistTask(required string speciesKey, string type="T001") {
		var familyKey = ListFirst(speciesKey, "|");
		var task = QueryExecute(
			"INSERT INTO dbo.configChecklistOfficeTask (
				stage,
				required,
				title,
				rank,
				familyKey,
				genusSpecifier,
				speciesSpecifier,
				taskType
			)
			OUTPUT Inserted.officeTaskID
			VALUES (
				N's1',
				1,
				N'Task',
				1,
				:familyKey,
				N'',
				N'',
				:type
			);",
			{
				familyKey: {cfsqltype: "nvarchar", value: familyKey},
				type: {cfsqltype: "nvarchar", value: type}
			}
		);

		return task.officeTaskID;
	}

}
