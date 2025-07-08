/// This persistent class is used to represent the available
/// set of priority levels used by the Incident class.
Class ZENApp.Data.Priority Extends (%Persistent, %Populate) [ Inheritance = right ]
{

/// Use priority name to identify priorities.
Index IdxName On Name [ IdKey ];

/// Display name of this priority.
Property Name As %String(MAXLEN = 100, POPSPEC = "Company()");

/// Build default set of priorities for the application
ClassMethod BuildData() As %Status
{
	Set tSC = $$$OK
	Do {
		For tName = "Low","High","Critical" {
			Set tObj = ..%New()
			Set tObj.Name = tName
			Set tSC = tObj.%Save()
			If $$$ISERR(tSC) Quit
			Set tObj = ""
		}
	} While(0)
	
	Quit tSC
}

Storage Default
{
<Data name="PriorityDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^ZENApp.Data.PriorityD</DataLocation>
<DefaultData>PriorityDefaultData</DefaultData>
<IdLocation>^ZENApp.Data.PriorityD</IdLocation>
<IndexLocation>^ZENApp.Data.PriorityI</IndexLocation>
<StreamLocation>^ZENApp.Data.PriorityS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

