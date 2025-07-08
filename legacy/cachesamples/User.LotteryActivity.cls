/// The <CLASS>LotteryUser</CLASS> class represents a specific user activity  
/// the CSP Lottery Example application.
Class User.LotteryActivity Extends %Persistent
{

Property TheUser As LotteryUser;

Property ActivityTime As %TimeStamp [ InitialExpression = {$zdt($H,3)}, Required ];

Property ActivityType As %String [ Required ];

Property Amount As %Integer [ InitialExpression = 0, Required ];

Property Product As %String [ Required ];

Storage Default
{
<Data name="LotteryActivityDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ActivityTime</Value>
</Value>
<Value name="3">
<Value>ActivityType</Value>
</Value>
<Value name="4">
<Value>Amount</Value>
</Value>
<Value name="5">
<Value>Product</Value>
</Value>
<Value name="6">
<Value>TheUser</Value>
</Value>
</Data>
<DataLocation>^User.LotteryActivityD</DataLocation>
<DefaultData>LotteryActivityDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^User.LotteryActivityD</IdLocation>
<IndexLocation>^User.LotteryActivityI</IndexLocation>
<StreamLocation>^User.LotteryActivityS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

