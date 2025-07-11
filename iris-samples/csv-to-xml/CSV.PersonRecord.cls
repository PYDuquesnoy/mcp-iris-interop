/// CSV Person Record Message Class
/// Represents a person record parsed from CSV data
Class CSV.PersonRecord Extends Ens.Request
{

/// First name from CSV
Property Firstname As %String(MAXLEN = 50) [ Required ];

/// Last name from CSV  
Property Lastname As %String(MAXLEN = 50) [ Required ];

/// Date of birth from CSV (YYYY-MM-DD format)
Property DOB As %String(MAXLEN = 10) [ Required ];

/// Address from CSV
Property Address As %String(MAXLEN = 200) [ Required ];

/// Export to XML for file output
Method %XMLExportToString(Output xmlString As %String) As %Status
{
    Set xmlString = ""
    Set xmlString = xmlString _ "<?xml version=""1.0"" encoding=""UTF-8""?>" _ $C(13,10)
    Set xmlString = xmlString _ "<Person>" _ $C(13,10)
    Set xmlString = xmlString _ "  <Firstname>" _ ..XMLEscape(..Firstname) _ "</Firstname>" _ $C(13,10)
    Set xmlString = xmlString _ "  <Lastname>" _ ..XMLEscape(..Lastname) _ "</Lastname>" _ $C(13,10)
    Set xmlString = xmlString _ "  <DOB>" _ ..XMLEscape(..DOB) _ "</DOB>" _ $C(13,10)
    Set xmlString = xmlString _ "  <Address>" _ ..XMLEscape(..Address) _ "</Address>" _ $C(13,10)
    Set xmlString = xmlString _ "</Person>" _ $C(13,10)
    
    Return $$$OK
}

/// Helper method to escape XML special characters
Method XMLEscape(input As %String) As %String
{
    Set result = input
    Set result = $Replace(result, "&", "&amp;")
    Set result = $Replace(result, "<", "&lt;")
    Set result = $Replace(result, ">", "&gt;")
    Set result = $Replace(result, """", "&quot;")
    Set result = $Replace(result, "'", "&apos;")
    Return result
}

/// Create from CSV line (assumes comma-separated values)
ClassMethod CreateFromCSVLine(csvLine As %String) As CSV.PersonRecord
{
    Set person = ##class(CSV.PersonRecord).%New()
    
    // Simple CSV parsing (assumes no commas in quoted fields for now)
    Set fields = $ListFromString(csvLine, ",")
    
    If $ListLength(fields) >= 4 {
        Set person.Firstname = $ZStrip($List(fields, 1), "<>W")
        Set person.Lastname = $ZStrip($List(fields, 2), "<>W")
        Set person.DOB = $ZStrip($List(fields, 3), "<>W")
        Set person.Address = $ZStrip($List(fields, 4), "<>W")
    }
    
    Return person
}

/// Display string for debugging
Method %DisplayString() As %String
{
    Return ..Firstname _ " " _ ..Lastname _ " (" _ ..DOB _ ")"
}

Storage Default
{
<Data name="PersonRecordDefaultData">
<Subscript>"PersonRecord"</Subscript>
<Value name="1">
<Value>Firstname</Value>
</Value>
<Value name="2">
<Value>Lastname</Value>
</Value>
<Value name="3">
<Value>DOB</Value>
</Value>
<Value name="4">
<Value>Address</Value>
</Value>
</Data>
<DefaultData>PersonRecordDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
