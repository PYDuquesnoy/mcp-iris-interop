/// This represents a customer support incident with 
/// the sample HelpDesk application.
Class ZENApp.Data.Incident Extends (%Persistent, %Populate) [ Inheritance = right ]
{

Index IdxAssignedTo On AssignedTo [ Type = bitmap ];

Index IdxCustomer On Customer [ Type = bitmap ];

Index IdxPriority On Priority [ Type = bitmap ];

Index IdxDate On CreateDate [ Type = bitmap ];

/// Customer who logged the incident.
Property Customer As Customer;

/// Employee to whom the incident is assigned.
Property AssignedTo As Employee;

/// Priority of this incident.
Property Priority As Priority;

/// Date on which this incident happened.
Property CreateDate As %Date(FORMAT = 3, POPSPEC = ".MakeDate()");

/// Comments related to this incident.
Property Comments As %String(MAXLEN = 5000, POPSPEC = ".MakeComment()");

/// Build sample data for the application
ClassMethod BuildData()
{
	#; wipe out old data
	Do ##class(Priority).%KillExtent()
	Do ##class(Customer).%KillExtent()
	Do ##class(Employee).%KillExtent()
	Do ##class(Incident).%KillExtent()

	#; build new data
	Do ##class(Priority).BuildData()
	Do ##class(Customer).Populate(100)
	Do ##class(Employee).Populate(100)
	Do ##class(Incident).Populate(1000)
}

/// Return random date for data population.
Method MakeDate() As %Date
{
	#; Make a random date within year 2005
	Quit 59901 + $R(300) + $R(65)
}

/// Return random comment for data population.
Method MakeComment() As %String
{
	Set tMsgs = $LB("We're working on it!","The customer is upset.")
	Quit $LG(tMsgs,$R($LL(tMsgs))+1)
}

Storage Default
{
<Data name="IncidentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>CreateDate</Value>
</Value>
<Value name="3">
<Value>Customer</Value>
</Value>
<Value name="4">
<Value>Priority</Value>
</Value>
<Value name="5">
<Value>AssignedTo</Value>
</Value>
<Value name="6">
<Value>Comments</Value>
</Value>
</Data>
<DataLocation>^ZENApp.Data.IncidentD</DataLocation>
<DefaultData>IncidentDefaultData</DefaultData>
<IdLocation>^ZENApp.Data.IncidentD</IdLocation>
<IndexLocation>^ZENApp.Data.IncidentI</IndexLocation>
<Property name="AssignedTo"/>
<Property name="Comments"/>
<Property name="CreateDate"/>
<Property name="Customer"/>
<Property name="Priority"/>
<StreamLocation>^ZENApp.Data.IncidentS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

