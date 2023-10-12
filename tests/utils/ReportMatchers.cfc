component {

	property xml xmlOutput;

	public ReportMatchers function init() {
		variables.xmlOutput = XMLNew();
	}

    public boolean function toBePdfHtmlOutputWithTitle(required expectation, args={}) {
		var title = args[1];
		var htmlStart = "<!DOCTYPE html>
<html>
	<head>
			<title>#title#</title>";

		var isGood = !isXML(expectation.actual) && expectation.actual.findNoCase(htmlStart) == 1;
		expectation.message = args.keyExists("message") 
			? args.message 
			: "The report does not have the correct output." & expectation.actual;

		return expectation.isNot ? !isGood : isGood;
	}

	private boolean function isXML(required stringToTest, args={}) {
		try {
			setXML(XmlParse(stringToTest));
			return true;
		}
		catch( any exception ) {
			return false;
		}
	}

	private void function setXML(required xml output) {
		variables.xmlOutput = output;
	}

	public boolean function toBeXmlOutputForStatisticalReport(required expectation, args={}) {
		var isGood = isXML(expectation.actual) && getXML().search("//row") > 0;

		expectation.message = args.keyExists("message") 
			? args.message 
			: "The report does not have the correct output." & expectation.actual;

		return expectation.isNot ? !isGood : isGood;
	}

	private xml function getXML() {
		return variables.xmlOutput;
	}

	public boolean function toHaveHTMLRows(required expectation, args={}) {
		var expectedRows = args[1] == 0 ? 1 : args[1];
		
		var actualRows = (expectation.actual.len() - expectation.actual.replace("<tr", "").len()) / Len("<tr");
		var isGood = actualRows == expectedRows;

		expectation.message = args.keyExists("message") 
			? args.message 
			: "Expected [#expectedRows#] rows but got [#expectation.actual#] rows";

		return expectation.isNot ? !isGood : isGood;
	}

	public boolean function toHaveXMLRows(required expectation, args={}) {
		var expectedRows = args[1] == 0 ? 1 : args[1];
		var actualRows = XmlParse(expectation.actual).search("//row");
		var isGood = actualRows == expectedRows;

		expectation.message = args.keyExists("message") 
			? args.message 
			: "Expected [#expectedRows#] rows but got [#expectation.actual#] rows";

		return expectation.isNot ? !isGood : isGood;
	}

}
