/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * A compat class for MXUnit Directory Test Suite
 */
component {

	function init(
		required directory,
		componentPath   = "",
		boolean recurse = true,
		excludes        = ""
	){
		for ( var thisArg in arguments ) {
			variables[ thisArg ] = arguments[ thisArg ];
		}

		return this;
	}

	any function getResultsOutput( mode = "simple" ){
		var dir = {
			recurse : variables.recurse,
			mapping : variables.componentPath,
			filter  : variables.filterExcludes
		};

		switch ( arguments.mode ) {
			case "junitxml": {
				arguments.mode = "junit";
				break;
			}
			case "query":
			case "array": {
				arguments.mode = "raw";
				break;
			}
			case "html":
			case "rawhtml": {
				arguments.mode = "simple";
				break;
			}
			default: {
				arguments.mode = "simple";
			}
		}

		var tb = new testbox.system.TestBox(
			directory = dir,
			reporter  = arguments.mode,
			options   = { excludes : variables.excludes }
		);

		return tb.run();
	}

	/**
	 * This will execute within the context of TestBox, it is not a closure as to remain cf9 compat
	 */
	private function filterExcludes( required path ){
		var excludes = getOptions().excludes;

		var className = listFirst( getFileFromPath( arguments.path ), "." );

		return ( listFindNoCase( excludes, className ) ? false : true );
	}

}
