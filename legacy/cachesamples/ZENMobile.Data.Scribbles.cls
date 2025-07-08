/// 
Class ZENMobile.Data.Scribbles Extends (%Persistent, %Populate) [ Inheritance = right ]
{

/// ScribbleName
Property Name As %String [ Required ];

/// Capture of a scribble area
Property Art As %String(MAXLEN = "");

Storage Default
{
<Data name="ScribblesDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Art</Value>
</Value>
</Data>
<DataLocation>^ZENMobile.Data.ScribblesD</DataLocation>
<DefaultData>ScribblesDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^ZENMobile.Data.ScribblesD</IdLocation>
<IndexLocation>^ZENMobile.Data.ScribblesI</IndexLocation>
<StreamLocation>^ZENMobile.Data.ScribblesS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

