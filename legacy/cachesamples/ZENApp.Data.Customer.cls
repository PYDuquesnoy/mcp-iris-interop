/// This represents a Customer within the sample 
/// HelpDesk application.
Class ZENApp.Data.Customer Extends (%Persistent, %Populate) [ Inheritance = right ]
{

Index IdxName On Name;

Index IdxLocation On Location [ Type = bitmap ];

/// Customer name.
Property Name As %String(MAXLEN = 100, POPSPEC = "Company()");

/// Customer location (city customer is based in).
Property Location As %String(MAXLEN = 100, POPSPEC = "City()");

Storage Default
{
<Data name="CustomerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Location</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
</Data>
<DataLocation>^ZENApp.Data.CustomerD</DataLocation>
<DefaultData>CustomerDefaultData</DefaultData>
<IdLocation>^ZENApp.Data.CustomerD</IdLocation>
<IndexLocation>^ZENApp.Data.CustomerI</IndexLocation>
<Property name="Location"/>
<Property name="Name"/>
<StreamLocation>^ZENApp.Data.CustomerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

