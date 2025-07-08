Class BasTutorial.Person Extends %Persistent
{

Property DOB As %Date;

Property Name As %String;

Property LastName As %String(COLLATION = "EXACT") [ Calculated, SqlComputeCode = {set {LastName}=$p({Name},",",1)}, SqlComputed ];

Property FirstName As %String(COLLATION = "EXACT") [ Calculated, SqlComputeCode = {set {FirstName}=$p({Name},",",2)}, SqlComputed ];

Property Phone As %String(COLLATION = "EXACT", MAXLEN = 12);

/// Index for property DOB
Index DOB On DOB;

/// Index for LastName,FirstName
Index Name On (LastName, FirstName);

/// Uniqueness index for property Phone
Index Phone On Phone [ Unique ];

Parameter MANAGEDEXTENT = 0;

Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Phone</Value>
</Value>
<Value name="3">
<Value>DOB</Value>
</Value>
<Value name="4">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^PersonD</IdLocation>
<IndexLocation>^PersonI</IndexLocation>
<StreamLocation>^BasTutor.PersonS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

