/**
 * A generic DataHandler class that handles generic database actions -- isolating queries
 * and logging.
 */
component {

	/**
	 * returns a function for use in aroundEach, that wraps a test in
	 * a transaction that is rolled back at the end.
	 *
	 * @preSpec A function to run after the start of the transaction, but before the actual test - for example, to prep the same data for every test
	 */
	public any function isolate(any preSpec="") {
		return function(required struct spec, required struct suite) {
			if( ( !IsClosure(preSpec) && !IsCustomFunction( preSpec ))) {
				preSpec = () => {};
			}

			transaction {
				preSpec();
				spec.body(data: suite.aroundEachData);

				transaction action="rollback";
			}
		};
	}

	/**
	 * Lookup debug logs from when the test was running
	 *
	 * @startTime the time that the test started
	 */
	public array function getDebugLogs(required date startTime) {
		return QueryExecute(
			"SELECT
				IOfficeLog.recnum,
				IOfficeLog.logLevel,
				IOfficeLog.classType,
				IOfficeLog.method,
				IOfficeLog.message,
				IOfficeLog.username,
				IOfficeLog.datestamp
			FROM dbo.IOfficeLog
			WHERE IOfficeLog.datestamp >= :startTime;",
			{ startTime: {cfsqltype: "timestamp", value: startTime} }
		).reduce((logs, row) => {
			row.message = IsJSON(row.message) ? DeserializeJSON(row.message) : row.message;
			return logs.append(row);
		}, []);
	}

		/**
	 * Outputs a struct of the data for debugging
	 * If an idnumber exists in the table/view that it wil filter ont he given idnumber.
	 * If the table does not have an idnumber column then it will list all data in the table.
	 *
	 * @idnumber the record to filter on
	 * @tables an array of tables and views to examine
	 */
	public struct function debug(required numeric idnumber, required string[] tables) {
		var data = {};
		for( var table in tables ) {
			var sql = "";
			if( tableExists(table) ) {
				sql = "SELECT * FROM #table#";
				if( hasIDNumber(table) ) {
					sql &= " WHERE idnumber = :idnumber";
				}
				var tableQuery = QueryExecute(sql, {idnumber: {cfsqltype: "integer", value: idnumber}});
				data[table] = tableQuery;
			}
		}
		return data;
	}

	/**
	 * verifies table exists
	 *
	 * @table the table to look for
	 */
	private boolean function tableExists(required string table) {
		return QueryExecute(
			"SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLES.TABLE_NAME = :table;",
			{ table: {cfsqltype: "nvarchar", value: table} }
		).recordCount > 0
	}

	/**
	 * Checks if the table has an idnumber column
	 *
	 * @table the table to check
	 */
	private boolean function hasIDNumber(required string table) {
		return QueryExecute(
			"SELECT 1
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE COLUMNS.TABLE_NAME = :table
				AND COLUMNS.COLUMN_NAME = 'idnumber';",
			{ table: {cfsqltype: "nvarchar", value: table} }
		).recordCount > 0
	}

}
