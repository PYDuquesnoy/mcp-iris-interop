/// Sample data class for Zen sample pages.
Class ZENDemo.Data.Patient Extends (%Persistent, %Populate) [ Inheritance = right ]
{

/// Index on Patient name
Index NameIdx On Name;

/// Index on SSN
Index SSNIdx On SSN;

/// Index on City
Index CityIdx On Home.City [ Type = bitmap ];

/// Index on State
Index StateIdx On Home.State [ Type = bitmap ];

/// Index on Patient sex
Index SexIdx On Sex [ Type = bitmap ];

/// Patient Name
Property Name As %String(MAXLEN = 100) [ Required ];

/// Patient SSN
Property SSN As %String(MAXLEN = 15);

/// Patient Marital Status
Property MaritalStatus As %String(MAXLEN = 1, VALUELIST = ",S,M,D,W,O");

/// Patient Sex
Property Sex As %String(MAXLEN = 1, VALUELIST = ",M,F,O");

/// Patient Date of Birth
Property DOB As %Date(FORMAT = 3, POPSPEC = ".MakeDOB()");

/// Patient's Favorite Color (so we can use a color control!)
Property FavoriteColor As %String(MAXLEN = 25, POPSPEC = ".MakeColor()");

/// Home address
Property Home As Address;

/// Next scheduled visit date.
Property NextVisit As %Date(FORMAT = 3, POPSPEC = ".MakeVisit()");

/// Memo field
Property Memo As %String(MAXLEN = 32000, POPSPEC = "Mission()");

/// Return a random color for data population.
Method MakeColor() As %String
{
	Quit $LG($LB("red","green","blue","black","orange","purple"),$R(6))
}

/// Return random birth date for data population.
Method MakeDOB() As %Date
{
	#; Make a random date within past 60 years
	Quit +$H - $R(365*60)
}

/// Return random visit date for data population.
Method MakeVisit() As %Date
{
	#; Make a random date within next year
	Quit +$H + $R(365)
}

Storage Default
{
<Data name="PatientDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DOB</Value>
</Value>
<Value name="3">
<Value>FavoriteColor</Value>
</Value>
<Value name="4">
<Value>Home</Value>
</Value>
<Value name="5">
<Value>Name</Value>
</Value>
<Value name="6">
<Value>SSN</Value>
</Value>
<Value name="7">
<Value>MaritalStatus</Value>
</Value>
<Value name="8">
<Value>Sex</Value>
</Value>
<Value name="9">
<Value>Memo</Value>
</Value>
<Value name="10">
<Value>NextVisit</Value>
</Value>
</Data>
<DataLocation>^ZENDemo.Data.PatientD</DataLocation>
<DefaultData>PatientDefaultData</DefaultData>
<IdLocation>^ZENDemo.Data.PatientD</IdLocation>
<IndexLocation>^ZENDemo.Data.PatientI</IndexLocation>
<Property name="DOB"/>
<Property name="FavoriteColor"/>
<Property name="Home"/>
<Property name="MaritalStatus"/>
<Property name="Memo"/>
<Property name="Name"/>
<Property name="SSN"/>
<Property name="Sex"/>
<StreamLocation>^ZENDemo.Data.PatientS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

