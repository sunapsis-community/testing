component {

    public array function parseDataLayer(required string response) {
        var records = [];
        try { 
            var responseXML = XMLParse(response);
            records = XMLSearch(responseXML, "//record");
        }
        catch( any exception ) {
            if( response.len() > 0 ) {
                Throw("[#response#] is not XML.", "InvalidArgumentException");
            }
        }

        return records;
    }

    public string function getValue(required xml record, required string key) {
        var datums = XMLSearch(record, '//datum[@key="#key#"]');
        if( datums.len() > 0 ) {
            return datums[1].XmlText;
        }
        return "";
    }

}
