/// This represents an Employee within the sample 
/// HelpDesk application.
Class ZENApp.Data.Employee Extends (%Persistent, %Populate) [ Inheritance = right ]
{

Index IdxName On Name;

Index IdxSSN On SSN;

/// Employee name.
Property Name As %String(MAXLEN = 100);

/// Employee SSN or Tax ID.
Property SSN As %String(MAXLEN = 20);

Storage Default
{
<Data name="EmployeeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>SSN</Value>
</Value>
</Data>
<DataLocation>^ZENApp.Data.EmployeeD</DataLocation>
<DefaultData>EmployeeDefaultData</DefaultData>
<IdLocation>^ZENApp.Data.EmployeeD</IdLocation>
<IndexLocation>^ZENApp.Data.EmployeeI</IndexLocation>
<Property name="Name"/>
<Property name="SSN"/>
<StreamLocation>^ZENApp.Data.EmployeeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

