<cfscript>
	import testbox.system.TestBox;
	
	cfsetting(requesttimeout: 600);
	
	reporter = url.keyExists("reporter") ? url.reporter : "Simple";
	testbox = new TestBox();
	
	testbox.addDirectory({ 
		mapping: "/tests", 
		filter: path => path.find("Application.cfc") == 0 
							&& path.find("utils") == 0
							&& path.find("testbox") == 0
	});
	WriteOutput(testbox.run(reporter: reporter));
</cfscript>