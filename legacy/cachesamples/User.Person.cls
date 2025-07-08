Class User.Person Extends (%Persistent, %Populate) [ Inheritance = right, ProcedureBlock ]
{

Property name As %String(POPSPEC = "Name()", TRUNCATE = 1);

Property city As %String(POPSPEC = "City()", TRUNCATE = 1);

Property dob As %Date;

Property score As %Integer(POPSPEC = "Integer(0,100)");

Property salary As %Float(POPSPEC = "Float(5000,400000,2)");

Index nameIDX On name [ Data = name ];

Index cityIDX On city As SQLSTRING [ Type = index ];

Index nsIDX On (name, score);

Index ncIDX On (name, city);

Index scoreIDX On score As SQLUPPER;

Index dobIDX On dob;

Index salaryIDX On salary;

Index salaryStrIDX On salary As SQLString;

Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>city</Value>
</Value>
<Value name="3">
<Value>dob</Value>
</Value>
<Value name="4">
<Value>name</Value>
</Value>
<Value name="5">
<Value>salary</Value>
</Value>
<Value name="6">
<Value>score</Value>
</Value>
</Data>
<DataLocation>^User.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^User.PersonD</IdLocation>
<IndexLocation>^User.PersonI</IndexLocation>
<StreamLocation>^User.PersonS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

