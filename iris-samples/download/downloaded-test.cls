/// A simple test class for Step 4 validation
Class Test.Sample Extends %Persistent
{

/// Sample property to store a name
Property Name As %String(MAXLEN = 100);

/// Sample property to store a number
Property Value As %Integer;

/// Sample property to store a date
Property CreatedDate As %Date [ InitialExpression = {$HOROLOG} ];

/// Simple method to demonstrate functionality
Method DisplayInfo() As %String
{
    Return "Name: " _ ..Name _ ", Value: " _ ..Value _ ", Date: " _ ..CreatedDate
}

/// Class method to create a sample object
ClassMethod CreateSample(name As %String, value As %Integer) As Test.Sample
{
    Set obj = ..%New()
    Set obj.Name = name
    Set obj.Value = value
    Return obj
}

/// Storage definition for the class
Storage Default
{
<Data name="SampleDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Value</Value>
</Value>
<Value name="4">
<Value>CreatedDate</Value>
</Value>
</Data>
<DataLocation>^Test.SampleD</DataLocation>
<DefaultData>SampleDefaultData</DefaultData>
<Description>
<![CDATA[Storage definition for the class]]></Description>
<IdLocation>^Test.SampleD</IdLocation>
<IndexLocation>^Test.SampleI</IndexLocation>
<StreamLocation>^Test.SampleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
