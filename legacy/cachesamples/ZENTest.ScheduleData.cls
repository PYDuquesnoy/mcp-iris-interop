/// This persistent class represents a set of appointments within a schedule.<br/>
/// This is used by the <class>ZENTest.SchedulePaneTest</class> test page.
Class ZENTest.ScheduleData Extends (%Persistent, %ZEN.DataModel.Adaptor) [ Inheritance = right ]
{

Index PersonIdx On Person;

Index TimeIdx On StartTime;

/// Person associated with the scheduled item.
Property Person As %String(MAXLEN = 100) [ Required ];

/// Reason (short title) for the scheduled item.
Property Reason As %String(MAXLEN = 50);

/// Notes for the scheduled item.
Property Notes As %String(MAXLEN = 10000);

/// Start time for the scheduled item.
Property StartTime As %TimeStamp [ Required ];

/// Duration (in minutes) of the scheduled item.
Property Duration As %Integer [ InitialExpression = 30, Required ];

/// Priority of the scheduled item.
Property Priority As %String(VALUELIST = ",Low,Normal,High") [ InitialExpression = "Normal" ];

Storage Default
{
<Data name="ScheduleDataDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Person</Value>
</Value>
<Value name="3">
<Value>Reason</Value>
</Value>
<Value name="4">
<Value>Notes</Value>
</Value>
<Value name="5">
<Value>StartTime</Value>
</Value>
<Value name="6">
<Value>Duration</Value>
</Value>
<Value name="7">
<Value>Priority</Value>
</Value>
</Data>
<DataLocation>^ZENTest.ScheduleDataD</DataLocation>
<DefaultData>ScheduleDataDefaultData</DefaultData>
<IdLocation>^ZENTest.ScheduleDataD</IdLocation>
<IndexLocation>^ZENTest.ScheduleDataI</IndexLocation>
<StreamLocation>^ZENTest.ScheduleDataS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

