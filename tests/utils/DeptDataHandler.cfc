component {

	/**
	 * Creates a departmental user with access to the given population
	 * 
	 * @dept the department (on iuieEmployee, iuieAdmissions, or iuieProgram)
	 * @area tells whether to look at employee (EMPL), admissions (ADMS), or program (PROG)
	 * @networkid lets you specify a username, if you need multiple department users
	 * 
	 * returns the network id of the departmental user
	 */
	public string function createDeptUser(required string dept, string area="EMPL", string networkid="test-user") {
		new ConfigDataHandler().setupTestCampus();

		var user = QueryExecute(
			"INSERT INTO dbo.IStartDepartmentRequester (
				networkid,
				name,
				universityEmail,
				campus,
				department,
				accessApproved,
				datestamp
			)
			OUTPUT Inserted.networkid, Inserted.campus
			VALUES (
				:username,
				N'Test User',
				CONCAT( :username, '@test.sunapsis.iu.edu' ),
				:campus,
				'TEST-DEPT',
				1,
				CURRENT_TIMESTAMP
			);",
			{
				username: {cfsqltype: "nvarchar", value: networkid},
				campus: {cfsqltype: "nvarchar", value: new ConfigDataHandler().getCampus()}
			}
		);

		QueryExecute(
			"INSERT INTO dbo.IStartDepartmentRequesterArea (
				networkid,
				areaType,
				campus,
				college,
				school,
				department,
				division
			)
			VALUES (
				:username,
				:area,
				:campus,
				N'',
				N'',
				:dept,
				N''
			);",
			{
				username: {cfsqltype: "nvarchar", value: user.networkid},
				area: {cfsqltype: "nvarchar", value: area},
				campus: {cfsqltype: "nvarchar", value: user.campus},
				dept: {cfsqltype: "nvarchar", value: dept}
			}
		);

		return user.networkid;
	}

}